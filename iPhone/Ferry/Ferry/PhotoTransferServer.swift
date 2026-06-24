import Foundation
import Network

actor PhotoTransferServer {
    let port: UInt16
    /// Per-session PIN that LAN clients must present to read or write Photos.
    /// `let` of a Sendable type is nonisolated, so the UI can read it synchronously.
    let accessPIN: String

    private var listener: NWListener?
    private var outgoingFiles: [OutgoingPhotoFile]
    private let onUpload: @Sendable (ReceivedUpload) async throws -> SavedMediaMetadata
    private let onUploadStarted: @Sendable (String) -> Void
    private let onUploadProgress: @Sendable (Double) -> Void
    private let onUploadFinished: @Sendable (UploadResult) -> Void
    private let onDownloadServed: @Sendable () -> Void
    /// Remaining free downloads the iPhone may serve. nil = unlimited (Pro).
    private var downloadAllowance: Int?

    init(
        port: UInt16,
        outgoingFiles: [OutgoingPhotoFile],
        onUpload: @escaping @Sendable (ReceivedUpload) async throws -> SavedMediaMetadata,
        onUploadStarted: @escaping @Sendable (String) -> Void,
        onUploadProgress: @escaping @Sendable (Double) -> Void,
        onUploadFinished: @escaping @Sendable (UploadResult) -> Void,
        onDownloadServed: @escaping @Sendable () -> Void
    ) {
        self.port = port
        self.accessPIN = Self.makeAccessPIN()
        self.outgoingFiles = outgoingFiles
        self.onUpload = onUpload
        self.onUploadStarted = onUploadStarted
        self.onUploadProgress = onUploadProgress
        self.onUploadFinished = onUploadFinished
        self.onDownloadServed = onDownloadServed
    }

    func setDownloadAllowance(_ value: Int?) {
        downloadAllowance = value
    }

    private static func makeAccessPIN() -> String {
        String(format: "%06d", Int.random(in: 0...999_999))
    }

    func start() async throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
        listener.service = NWListener.Service(name: "Ferry", type: "_http._tcp")
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else {
                connection.cancel()
                return
            }
            Task {
                await self.handle(connection)
            }
        }
        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    func updateOutgoingFiles(_ files: [OutgoingPhotoFile]) {
        outgoingFiles = files
    }

    private func handle(_ connection: NWConnection) async {
        connection.start(queue: .global(qos: .userInitiated))

        do {
            let envelope = try await receiveHTTPRequestEnvelope(from: connection)
            let request = envelope.request

            if requiresAuthorization(method: request.method, path: request.path),
               !isAuthorized(request) {
                await send(
                    .unauthorized("Enter the PIN shown in the Ferry app to continue."),
                    over: connection
                )
                return
            }

            switch (request.method, request.path) {
            case ("GET", "/"):
                await send(.html(homePageHTML()), over: connection)
            case ("GET", "/manifest.json"):
                await send(.json(manifestJSON()), over: connection)
            case ("GET", let path) where path.hasPrefix("/download/"):
                await sendDownload(path: path, over: connection)
            case ("POST", "/upload"):
                await receiveUpload(
                    request,
                    initialBody: envelope.initialBody,
                    bodyTransfer: envelope.bodyTransfer,
                    over: connection
                )
            default:
                await send(.notFound("That transfer route does not exist."), over: connection)
            }
        } catch {
            await send(.badRequest(error.localizedDescription), over: connection)
        }
    }

    private func requiresAuthorization(method: String, path: String) -> Bool {
        // The landing page is public so a manually-typed address can show the PIN
        // prompt; every route that touches Photos requires the PIN.
        !(method == "GET" && path == "/")
    }

    private func isAuthorized(_ request: HTTPRequest) -> Bool {
        guard let provided = request.query["pin"] ?? request.headers["x-access-pin"] else {
            return false
        }
        return Self.constantTimeEquals(provided, accessPIN)
    }

    private static func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf8)
        let right = Array(rhs.utf8)
        guard left.count == right.count else { return false }

        var difference: UInt8 = 0
        for index in left.indices {
            difference |= left[index] ^ right[index]
        }
        return difference == 0
    }

    private func receiveUpload(
        _ request: HTTPRequest,
        initialBody: Data,
        bodyTransfer: HTTPBodyTransfer,
        over connection: NWConnection
    ) async {
        let fallbackName = "android-media"
        let filename = uploadFilename(from: request, fallback: fallbackName)
        onUploadStarted(filename)

        do {
            let uploadDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("FerryUploads", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
            defer {
                // The bytes are copied into Photos during onUpload, so the staging
                // directory can go regardless of whether the save succeeded.
                try? FileManager.default.removeItem(at: uploadDirectory)
            }

            let destination = uploadDirectory.appendingPathComponent(filename)
            try await writeUploadBody(
                to: destination,
                initialBody: initialBody,
                bodyTransfer: bodyTransfer,
                from: connection
            )

            let metadata = try await onUpload(ReceivedUpload(
                filename: filename,
                fileURL: destination,
                contentType: request.headers["content-type"],
                latitude: request.headers["x-media-latitude"].flatMap(Double.init),
                longitude: request.headers["x-media-longitude"].flatMap(Double.init),
                dateMillis: request.headers["x-media-date"].flatMap(Double.init)
            ))
            let result = UploadResult(
                filename: metadata.savedFilename,
                message: "Saved \(metadata.savedFilename) to Photos. \(metadata.locationMessage)",
                didSave: true,
                localIdentifier: metadata.localIdentifier
            )
            onUploadFinished(result)
            await send(.json(jsonString([
                "ok": true,
                "filename": metadata.savedFilename,
                "message": result.message
            ])), over: connection)
        } catch {
            let result = UploadResult(
                filename: filename,
                message: "Could not save \(filename): \(error.localizedDescription)",
                didSave: false
            )
            onUploadFinished(result)
            await send(.serverError(result.message), over: connection)
        }
    }

    private func writeUploadBody(
        to destination: URL,
        initialBody: Data,
        bodyTransfer: HTTPBodyTransfer,
        from connection: NWConnection
    ) async throws {
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer {
            try? handle.close()
        }

        switch bodyTransfer {
        case .fixedLength(let remainingByteCount):
            let total = initialBody.count + remainingByteCount
            try handle.write(contentsOf: initialBody)
            if total > 0 {
                onUploadProgress(Double(initialBody.count) / Double(total))
            }
            try await writeFixedLengthUploadBody(
                to: handle,
                remainingByteCount: remainingByteCount,
                alreadyWritten: initialBody.count,
                totalBytes: total,
                from: connection
            )
        case .chunked:
            // Length is unknown for chunked uploads, so progress stays indeterminate.
            onUploadProgress(0)
            try await writeChunkedUploadBody(
                to: handle,
                initialBody: initialBody,
                from: connection
            )
        case .empty:
            break
        }
    }

    private func writeFixedLengthUploadBody(
        to handle: FileHandle,
        remainingByteCount: Int,
        alreadyWritten: Int,
        totalBytes: Int,
        from connection: NWConnection
    ) async throws {
        var remaining = remainingByteCount
        var written = alreadyWritten
        while remaining > 0 {
            let chunk = try await connection.receiveData(
                minimumIncompleteLength: 1,
                maximumLength: min(1_048_576, remaining)
            )

            guard !chunk.isEmpty else {
                throw TransferServerError.incompleteUpload
            }

            try handle.write(contentsOf: chunk)
            remaining -= chunk.count
            written += chunk.count
            if totalBytes > 0 {
                onUploadProgress(Double(written) / Double(totalBytes))
            }
        }
    }

    private func writeChunkedUploadBody(
        to handle: FileHandle,
        initialBody: Data,
        from connection: NWConnection
    ) async throws {
        var buffer = initialBody
        let crlf = Data("\r\n".utf8)
        let trailerTerminator = Data("\r\n\r\n".utf8)

        while true {
            guard let headerRange = buffer.range(of: crlf) else {
                let chunk = try await connection.receiveData(minimumIncompleteLength: 1, maximumLength: 1_048_576)
                guard !chunk.isEmpty else { throw TransferServerError.incompleteUpload }
                buffer.append(chunk)
                continue
            }

            guard let sizeLine = String(data: buffer[..<headerRange.lowerBound], encoding: .ascii) else {
                throw TransferServerError.invalidChunkedUpload
            }

            let sizeText = sizeLine
                .split(separator: ";", maxSplits: 1)
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let chunkSize = Int(sizeText, radix: 16) else {
                throw TransferServerError.invalidChunkedUpload
            }

            let chunkStart = headerRange.upperBound
            if chunkSize == 0 {
                let trailerData = Data(buffer[chunkStart...])
                if trailerData.starts(with: crlf) || trailerData.range(of: trailerTerminator) != nil {
                    return
                }

                let chunk = try await connection.receiveData(minimumIncompleteLength: 1, maximumLength: 1_048_576)
                guard !chunk.isEmpty else { throw TransferServerError.incompleteUpload }
                buffer.append(chunk)
                continue
            }

            let chunkEnd = chunkStart + chunkSize
            let requiredEnd = chunkEnd + crlf.count
            guard buffer.count >= requiredEnd else {
                let chunk = try await connection.receiveData(minimumIncompleteLength: 1, maximumLength: 1_048_576)
                guard !chunk.isEmpty else { throw TransferServerError.incompleteUpload }
                buffer.append(chunk)
                continue
            }

            guard Data(buffer[chunkEnd..<requiredEnd]) == crlf else {
                throw TransferServerError.invalidChunkedUpload
            }

            try handle.write(contentsOf: Data(buffer[chunkStart..<chunkEnd]))
            buffer.removeSubrange(..<requiredEnd)
        }
    }

    private func sendDownload(path: String, over connection: NWConnection) async {
        let id = path.components(separatedBy: "/").dropFirst(2).first
        guard let id,
              let file = outgoingFiles.first(where: { $0.id == id }) else {
            await send(.notFound("The selected file is no longer available."), over: connection)
            return
        }

        if let allowance = downloadAllowance, allowance <= 0 {
            await send(
                .unauthorized("The iPhone reached its free limit of 50 lifetime transfers. Ferry Pro unlocks unlimited."),
                over: connection
            )
            return
        }

        do {
            let fileSize = try fileByteCount(at: file.url)
            let headers = [
                "Content-Type": contentType(for: file.filename),
                "Content-Length": "\(fileSize)",
                "Content-Disposition": "attachment; filename=\"\(file.filename.replacingOccurrences(of: "\"", with: ""))\"",
                "Connection": "close"
            ]
            try await streamFile(at: file.url, status: "HTTP/1.1 200 OK", headers: headers, over: connection)
            if downloadAllowance != nil {
                downloadAllowance? -= 1
            }
            onDownloadServed()
        } catch {
            await send(.serverError("Could not read the original photo file."), over: connection)
        }
    }

    private func fileByteCount(at url: URL) throws -> Int {
        let values = try url.resourceValues(forKeys: Set<URLResourceKey>([.fileSizeKey]))
        return values.fileSize ?? 0
    }

    private func streamFile(
        at url: URL,
        status: String,
        headers: [String: String],
        over connection: NWConnection
    ) async throws {
        // Open before writing the header block: a failure here still lets the caller
        // fall back to a 500 (nothing has been sent yet).
        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }

        var header = status + "\r\n"
        for (key, value) in headers {
            header += "\(key): \(value)\r\n"
        }
        header += "\r\n"
        try await connection.sendData(Data(header.utf8))

        // Read/send in bounded chunks so a multi-GB video never sits in memory. Each
        // send awaits `contentProcessed`, giving natural backpressure.
        let chunkSize = 256 * 1024
        while let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty {
            try await connection.sendData(chunk)
        }

        connection.cancel()
    }

    private func receiveHTTPRequestEnvelope(from connection: NWConnection) async throws -> HTTPRequestEnvelope {
        // Guards against a client that opens a connection and never terminates the
        // header block: without a cap the buffer would grow until the socket closed.
        let maxHeaderByteCount = 64 * 1024
        var buffer = Data()

        while true {
            let chunk = try await connection.receiveData(minimumIncompleteLength: 1, maximumLength: 1_048_576)
            if chunk.isEmpty {
                break
            }

            buffer.append(chunk)

            if let headerRange = buffer.range(of: Data("\r\n\r\n".utf8)),
               let headerText = String(data: buffer[..<headerRange.lowerBound], encoding: .utf8) {
                guard let request = HTTPRequest(headerText: headerText) else {
                    throw TransferServerError.invalidRequest
                }
                let bodyData = Data(buffer[headerRange.upperBound...])
                let contentLength = request.contentLength
                let isChunked = request.headers["transfer-encoding"]?
                    .lowercased()
                    .contains("chunked") == true

                let initialBody: Data
                let bodyTransfer: HTTPBodyTransfer

                if isChunked {
                    initialBody = bodyData
                    bodyTransfer = .chunked
                } else if let contentLength {
                    initialBody = Data(bodyData.prefix(contentLength))
                    bodyTransfer = .fixedLength(remainingByteCount: max(0, contentLength - initialBody.count))
                } else {
                    initialBody = Data()
                    bodyTransfer = .empty
                }

                return HTTPRequestEnvelope(
                    request: request,
                    initialBody: initialBody,
                    bodyTransfer: bodyTransfer
                )
            }

            if buffer.count > maxHeaderByteCount {
                throw TransferServerError.headerTooLarge
            }
        }

        throw TransferServerError.invalidRequest
    }

    private func send(_ response: HTTPResponse, over connection: NWConnection) async {
        await sendRaw(
            status: response.status,
            headers: response.headers,
            body: Data(response.body.utf8),
            over: connection
        )
    }

    private func sendRaw(status: String, headers: [String: String], body: Data, over connection: NWConnection) async {
        var mergedHeaders = headers
        mergedHeaders["Content-Length"] = "\(body.count)"
        mergedHeaders["Connection"] = "close"

        var header = status + "\r\n"
        for (key, value) in mergedHeaders {
            header += "\(key): \(value)\r\n"
        }
        header += "\r\n"

        var data = Data(header.utf8)
        data.append(body)

        do {
            try await connection.sendData(data)
        } catch {
            connection.cancel()
            return
        }

        connection.cancel()
    }

    private func manifestJSON() -> String {
        let items = outgoingFiles.map { file in
            let encodedName = file.filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.filename
            return [
                "name": file.filename,
                "size": file.byteSize,
                "url": "/download/\(file.id)/\(encodedName)"
            ] as [String: Any]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: ["files": items], options: []),
              let json = String(data: data, encoding: .utf8) else {
            return #"{"files":[]}"#
        }

        return json
    }

    private func homePageHTML() -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="Cache-Control" content="no-store">
          <title>Ferry</title>
          <script>
            (function () {
              var saved = localStorage.getItem('gt-theme');
              var theme = saved || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
              document.documentElement.setAttribute('data-theme', theme);
            })();
          </script>
          <style>
            :root, [data-theme="light"] {
              --bg: #f4eddc; --surface: #fffdf6; --surface-2: #ece3cf;
              --text: #1f2a23; --muted: #6c6450;
              --primary: #1f5130; --on-primary: #fbf7ec; --accent: #b07d12;
              --border: #e0d7c0; --shadow: 0 1px 3px rgba(31,42,35,0.10);
              --success-bg: #e7f6ec; --success-fg: #14532d; --success-pill: #16a34a;
              --error-bg: #fbeceb; --error-fg: #7f1d1d; --error-pill: #dc2626;
            }
            [data-theme="dark"] {
              --bg: #080d0a; --surface: #0f1c15; --surface-2: #16271d;
              --text: #f0ecde; --muted: #9bb0a2;
              --primary: #2f9159; --on-primary: #06140c; --accent: #d8b450;
              --border: #1e3327; --shadow: 0 1px 3px rgba(0,0,0,0.45);
              --success-bg: #0f2a1b; --success-fg: #7ee2a8; --success-pill: #16a34a;
              --error-bg: #2a1414; --error-fg: #f1a8a8; --error-pill: #dc2626;
            }
            * { box-sizing: border-box; }
            body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: var(--bg); color: var(--text); transition: background 0.2s, color 0.2s; }
            main { max-width: 680px; margin: 0 auto; padding: 20px; }
            .appbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 4px 0 6px; }
            .brand { display: flex; align-items: center; gap: 10px; }
            .brand-mark { width: 26px; height: 26px; border-radius: 7px; background: var(--primary); position: relative; flex: 0 0 auto; }
            .brand-mark::after { content: ""; position: absolute; right: 5px; bottom: 5px; width: 8px; height: 8px; border-radius: 2px; background: var(--accent); }
            h1 { font-size: 22px; margin: 0; letter-spacing: 0.2px; }
            h2 { font-size: 17px; margin: 0 0 10px; }
            p { color: var(--muted); line-height: 1.45; }
            section { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 16px; margin: 14px 0; box-shadow: var(--shadow); }
            input, button, a.button { font: inherit; }
            input[type="file"] { display: block; margin: 12px 0; max-width: 100%; color: var(--text); }
            button, a.button { border: 0; border-radius: 10px; padding: 11px 15px; background: var(--primary); color: var(--on-primary); text-decoration: none; display: inline-block; font-weight: 600; cursor: pointer; }
            button:active, a.button:active { opacity: 0.85; }
            .theme-toggle { background: var(--surface-2); color: var(--text); border: 1px solid var(--border); padding: 8px 12px; border-radius: 999px; font-size: 14px; font-weight: 600; }
            .summary { margin: 10px 0 4px; font-weight: 600; color: var(--text); display: none; }
            .summary .chip { display: inline-block; background: var(--surface-2); border: 1px solid var(--border); color: var(--accent); border-radius: 999px; padding: 4px 10px; }
            .hint { font-size: 13px; color: var(--muted); margin-top: 8px; }
            .pin-input { display: block; margin: 12px 0; width: 170px; padding: 12px; font-size: 22px; letter-spacing: 6px; text-align: center; border: 1px solid var(--border); border-radius: 10px; background: var(--surface-2); color: var(--text); }
            .pin-error { color: var(--error-pill); margin-top: 8px; min-height: 1.2em; }
            .row-list { display: grid; gap: 8px; margin-top: 12px; }
            .row { display: flex; align-items: center; justify-content: space-between; gap: 12px; border-radius: 10px; padding: 11px 13px; background: var(--surface-2); border: 1px solid var(--border); color: var(--text); }
            .row-name { min-width: 0; overflow-wrap: anywhere; font-weight: 600; }
            .row-sub { font-size: 12px; color: var(--muted); margin-top: 2px; }
            .row-state { flex: 0 0 auto; border-radius: 999px; padding: 4px 9px; font-size: 13px; font-weight: 700; background: var(--border); color: var(--muted); }
            .row.success { background: var(--success-bg); color: var(--success-fg); border-color: transparent; }
            .row.success .row-state { background: var(--success-pill); color: white; }
            .row.error { background: var(--error-bg); color: var(--error-fg); border-color: transparent; }
            .row.error .row-state { background: var(--error-pill); color: white; }
            .empty { color: var(--muted); margin-top: 12px; }
            .download-link { flex: 0 0 auto; padding: 8px 13px; }
            .install { border-left: 4px solid var(--accent); }
            .install .button { margin-top: 6px; }
          </style>
        </head>
        <body>
          <main>
            <div class="appbar">
              <div class="brand">
                <div class="brand-mark"></div>
                <h1>Ferry</h1>
              </div>
              <button id="themeToggle" class="theme-toggle" onclick="toggleTheme()">Theme</button>
            </div>
            <p>Transfers use the original media file. Keep this iPhone app open until everything finishes.</p>

            <section id="installBanner" class="install" style="display:none">
              <h2>Get the Android app</h2>
              <p>Install the companion app to keep photo <strong>location</strong> and original <strong>filenames</strong> - a browser upload loses both.</p>
              <a class="button" href="https://github.com/shveatamishra-rgb/PhoneApps/releases/latest/download/ferry.apk">Download Android app (.apk)</a>
            </section>

            <section id="pinSection" style="display:none">
              <h2>Enter PIN</h2>
              <p>Type the 6-digit PIN shown in the Ferry app on the iPhone.</p>
              <input id="pinInput" class="pin-input" inputmode="numeric" maxlength="6" placeholder="000000" autocomplete="off">
              <button onclick="savePin()">Continue</button>
              <div id="pinError" class="pin-error"></div>
            </section>

            <div id="appSections" style="display:none">
              <section>
                <h2>Send to iPhone</h2>
                <p>Pick photos or videos on this Android phone, check the total, then upload - each one saves straight into iPhone Photos.</p>
                <input id="files" type="file" accept="image/*,video/*" multiple onchange="showSelection()">
                <div id="selectionSummary" class="summary"></div>
                <button onclick="uploadFiles()">Upload to iPhone Photos</button>
                <div id="uploadStatus" class="row-list"></div>
              </section>

              <section>
                <h2>Get from iPhone</h2>
                <p>Choose photos or videos in the iPhone app first. They appear here with their size, ready to download.</p>
                <button onclick="loadDownloads()">Refresh list</button>
                <div id="downloads" class="row-list"></div>
              </section>
            </div>
          </main>

          <script>
            let pin = new URLSearchParams(location.search).get('pin') || '';

            function withPin(url) {
              const separator = url.includes('?') ? '&' : '?';
              return url + separator + 'pin=' + encodeURIComponent(pin);
            }

            function updateThemeButton() {
              const theme = document.documentElement.getAttribute('data-theme');
              const btn = document.getElementById('themeToggle');
              if (btn) btn.textContent = theme === 'dark' ? '☀ Light' : '☾ Dark';
            }

            function toggleTheme() {
              const current = document.documentElement.getAttribute('data-theme');
              const next = current === 'dark' ? 'light' : 'dark';
              document.documentElement.setAttribute('data-theme', next);
              localStorage.setItem('gt-theme', next);
              updateThemeButton();
            }

            function formatBytes(bytes) {
              if (!bytes) return '0 B';
              const units = ['B', 'KB', 'MB', 'GB', 'TB'];
              let value = bytes, i = 0;
              while (value >= 1024 && i < units.length - 1) { value /= 1024; i++; }
              const decimals = (i === 0 || value >= 100) ? 0 : 1;
              return value.toFixed(decimals) + ' ' + units[i];
            }

            function showSelection() {
              const input = document.getElementById('files');
              const summary = document.getElementById('selectionSummary');
              const files = input.files;
              if (!files.length) { summary.style.display = 'none'; summary.textContent = ''; return; }
              let total = 0;
              for (const file of files) total += file.size;
              const noun = files.length === 1 ? 'item' : 'items';
              summary.innerHTML = `<span class="chip">${files.length} ${noun} &middot; ${formatBytes(total)} total</span>`;
              summary.style.display = 'block';
            }

            function showApp() {
              document.getElementById('pinSection').style.display = 'none';
              document.getElementById('appSections').style.display = '';
              loadDownloads();
            }

            function promptForPin(message) {
              pin = '';
              document.getElementById('appSections').style.display = 'none';
              document.getElementById('pinSection').style.display = '';
              document.getElementById('pinError').textContent = message || '';
            }

            function savePin() {
              const value = document.getElementById('pinInput').value.trim();
              if (!value) {
                document.getElementById('pinError').textContent = 'Enter the PIN to continue.';
                return;
              }
              pin = value;
              showApp();
            }

            async function uploadFiles() {
              const input = document.getElementById('files');
              const status = document.getElementById('uploadStatus');
              if (!input.files.length) {
                status.innerHTML = '<div class="empty">Choose one or more photos or videos first.</div>';
                return;
              }
              status.innerHTML = '';
              for (const file of input.files) {
                const filename = file.name || 'android-media';
                const row = document.createElement('div');
                row.className = 'row';
                const name = document.createElement('div');
                name.className = 'row-name';
                name.textContent = filename;
                const sub = document.createElement('div');
                sub.className = 'row-sub';
                sub.textContent = formatBytes(file.size);
                name.appendChild(sub);
                const state = document.createElement('span');
                state.className = 'row-state';
                state.textContent = 'Uploading...';
                row.appendChild(name);
                row.appendChild(state);
                status.appendChild(row);
                try {
                  const response = await fetch(withPin(`/upload?filename=${encodeURIComponent(filename)}`), {
                    method: 'POST',
                    headers: {
                      'Content-Type': file.type || 'application/octet-stream',
                      'X-Original-Filename': encodeURIComponent(filename)
                    },
                    body: file,
                    cache: 'no-store'
                  });
                  if (response.status === 401) {
                    row.classList.add('error');
                    state.textContent = 'PIN needed';
                    name.textContent = `${filename}: enter the PIN to continue.`;
                    promptForPin('That PIN did not match. Try again.');
                    return;
                  }
                  const text = await response.text();
                  let payload = null;
                  try { payload = JSON.parse(text); } catch (_) {}
                  if (response.ok) {
                    name.textContent = payload?.filename || filename;
                    row.classList.add('success');
                    state.textContent = 'Uploaded';
                  } else {
                    row.classList.add('error');
                    state.textContent = 'Failed';
                    name.textContent = `${filename}: ${payload?.message || text || response.statusText}`;
                  }
                } catch (error) {
                  row.classList.add('error');
                  state.textContent = 'Failed';
                  name.textContent = `${filename}: ${error?.message || error}`;
                }
              }
            }

            async function loadDownloads() {
              const list = document.getElementById('downloads');
              list.innerHTML = '';
              const response = await fetch(withPin('/manifest.json'), { cache: 'no-store' });
              if (response.status === 401) {
                promptForPin('That PIN did not match. Try again.');
                return;
              }
              const manifest = await response.json();
              if (!manifest.files.length) {
                list.innerHTML = '<div class="empty">No iPhone media selected yet.</div>';
                return;
              }
              let total = 0;
              for (const file of manifest.files) {
                total += file.size || 0;
                const row = document.createElement('div');
                row.className = 'row';
                const info = document.createElement('div');
                info.className = 'row-name';
                info.textContent = file.name;
                const sub = document.createElement('div');
                sub.className = 'row-sub';
                sub.textContent = formatBytes(file.size || 0);
                info.appendChild(sub);
                const link = document.createElement('a');
                link.className = 'button download-link';
                link.href = withPin(file.url);
                link.setAttribute('download', file.name);
                link.textContent = 'Download';
                row.appendChild(info);
                row.appendChild(link);
                list.appendChild(row);
              }
              const noun = manifest.files.length === 1 ? 'file' : 'files';
              const totalRow = document.createElement('div');
              totalRow.className = 'summary';
              totalRow.style.display = 'block';
              totalRow.innerHTML = `<span class="chip">${manifest.files.length} ${noun} &middot; ${formatBytes(total)} total</span>`;
              list.appendChild(totalRow);
            }

            updateThemeButton();

            // Only Android visitors can use the companion APK, so only they see the offer.
            if (/Android/i.test(navigator.userAgent)) {
              document.getElementById('installBanner').style.display = '';
            }

            if (pin) {
              showApp();
            } else {
              promptForPin('');
            }
          </script>
        </body>
        </html>
        """
    }

    private func uploadFilename(from request: HTTPRequest, fallback: String) -> String {
        let candidates = [
            request.headers["x-original-filename"]?.removingPercentEncoding,
            request.query["filename"],
            request.headers["content-disposition"].flatMap(contentDispositionFilename)
        ]

        for candidate in candidates {
            guard let candidate else { continue }
            let filename = safeFilename(candidate, fallback: fallback)
            if filename != fallback {
                return filename
            }
        }

        return safeFilename(fallback, fallback: fallback)
    }

    private func contentDispositionFilename(_ header: String) -> String? {
        for part in header.components(separatedBy: ";") {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("filename*=") {
                let value = String(trimmed.dropFirst("filename*=".count)).trimmingFilenameQuotes()
                if let encoded = value.split(separator: "'", maxSplits: 2).last {
                    return String(encoded).removingPercentEncoding ?? String(encoded)
                }
                return value.removingPercentEncoding ?? value
            }

            if trimmed.lowercased().hasPrefix("filename=") {
                return String(trimmed.dropFirst("filename=".count)).trimmingFilenameQuotes()
            }
        }

        return nil
    }
}

private enum TransferServerError: LocalizedError {
    case invalidRequest
    case headerTooLarge
    case incompleteUpload
    case invalidChunkedUpload

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Could not read the request."
        case .headerTooLarge:
            return "The request headers were too large."
        case .incompleteUpload:
            return "The upload ended before the whole file arrived."
        case .invalidChunkedUpload:
            return "The browser sent an upload stream that could not be decoded."
        }
    }
}

private struct HTTPRequestEnvelope {
    let request: HTTPRequest
    let initialBody: Data
    let bodyTransfer: HTTPBodyTransfer
}

private enum HTTPBodyTransfer {
    case fixedLength(remainingByteCount: Int)
    case chunked
    case empty
}

private struct HTTPRequest {
    let method: String
    let path: String
    let query: [String: String]
    let headers: [String: String]

    init?(headerText: String) {
        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }

        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else {
            return nil
        }

        method = parts[0]

        var components = URLComponents()
        components.percentEncodedPath = parts[1].split(separator: "?", maxSplits: 1).first.map(String.init) ?? "/"
        if let queryPart = parts[1].split(separator: "?", maxSplits: 1).dropFirst().first {
            components.percentEncodedQuery = String(queryPart)
        }
        path = components.path.isEmpty ? "/" : components.path
        query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        var parsedHeaders: [String: String] = [:]
        for line in lines.dropFirst() {
            let headerParts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard headerParts.count == 2 else { continue }
            parsedHeaders[headerParts[0].lowercased()] = headerParts[1].trimmingCharacters(in: .whitespaces)
        }
        headers = parsedHeaders
    }

    var contentLength: Int? {
        guard let value = headers["content-length"] else {
            return nil
        }
        return Int(value.trimmingCharacters(in: .whitespaces))
    }
}

private struct HTTPResponse {
    let status: String
    let headers: [String: String]
    let body: String

    static func html(_ body: String) -> HTTPResponse {
        HTTPResponse(
            status: "HTTP/1.1 200 OK",
            headers: noCacheHeaders(["Content-Type": "text/html; charset=utf-8"]),
            body: body
        )
    }

    static func json(_ body: String) -> HTTPResponse {
        HTTPResponse(
            status: "HTTP/1.1 200 OK",
            headers: noCacheHeaders(["Content-Type": "application/json; charset=utf-8"]),
            body: body
        )
    }

    static func badRequest(_ body: String) -> HTTPResponse {
        HTTPResponse(status: "HTTP/1.1 400 Bad Request", headers: ["Content-Type": "text/plain; charset=utf-8"], body: body)
    }

    static func notFound(_ body: String) -> HTTPResponse {
        HTTPResponse(status: "HTTP/1.1 404 Not Found", headers: ["Content-Type": "text/plain; charset=utf-8"], body: body)
    }

    static func unauthorized(_ body: String) -> HTTPResponse {
        HTTPResponse(status: "HTTP/1.1 401 Unauthorized", headers: ["Content-Type": "text/plain; charset=utf-8"], body: body)
    }

    static func serverError(_ body: String) -> HTTPResponse {
        HTTPResponse(status: "HTTP/1.1 500 Internal Server Error", headers: ["Content-Type": "text/plain; charset=utf-8"], body: body)
    }

    private static func noCacheHeaders(_ headers: [String: String]) -> [String: String] {
        var headers = headers
        headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        headers["Pragma"] = "no-cache"
        headers["Expires"] = "0"
        return headers
    }
}

private extension NWConnection {
    func receiveData(minimumIncompleteLength: Int, maximumLength: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            receive(minimumIncompleteLength: minimumIncompleteLength, maximumLength: maximumLength) { data, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data ?? Data())
                }
            }
        }
    }

    func sendData(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}

private func contentType(for filename: String) -> String {
    switch URL(fileURLWithPath: filename).pathExtension.lowercased() {
    case "jpg", "jpeg":
        return "image/jpeg"
    case "png":
        return "image/png"
    case "heic":
        return "image/heic"
    case "heif":
        return "image/heif"
    case "gif":
        return "image/gif"
    case "webp":
        return "image/webp"
    case "mp4":
        return "video/mp4"
    case "mov":
        return "video/quicktime"
    case "m4v":
        return "video/x-m4v"
    case "3gp", "3gpp":
        return "video/3gpp"
    case "webm":
        return "video/webm"
    default:
        return "application/octet-stream"
    }
}

private func jsonString(_ object: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: []),
          let string = String(data: data, encoding: .utf8) else {
        return #"{"ok":false}"#
    }

    return string
}

private extension String {
    func trimmingFilenameQuotes() -> String {
        let trimmed = trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2,
              trimmed.first == "\"",
              trimmed.last == "\"" else {
            return trimmed
        }

        return String(trimmed.dropFirst().dropLast())
    }
}
