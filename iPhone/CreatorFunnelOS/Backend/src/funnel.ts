export function keywordMatches(comment: string, keyword: string): boolean {
  const normalized = comment.normalize("NFKC").toLocaleUpperCase();
  const target = keyword.normalize("NFKC").trim().toLocaleUpperCase();
  return normalized.split(/[^\p{L}\p{N}_]+/u).includes(target);
}
