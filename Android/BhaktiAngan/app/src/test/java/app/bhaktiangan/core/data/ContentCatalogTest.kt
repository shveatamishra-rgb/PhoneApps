package app.bhaktiangan.core.data

import app.bhaktiangan.core.model.DeityCategory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ContentCatalogTest {

    @Test
    fun itemCount_isSixtySlugsMinusRemoved() {
        // 60 slugs, all map to a template, 9 removed -> 51 surviving items.
        assertEquals(51, ContentCatalog.items.size)
    }

    @Test
    fun removedImages_areAbsent() {
        val names = ContentCatalog.items.map { it.imageName }.toSet()
        ContentCatalog.removedImageNames.forEach { assertFalse(it in names) }
    }

    @Test
    fun freeSplit_isPositionBasedAtTwelve() {
        ContentCatalog.items.take(ContentCatalog.FREE_DARSHAN_COUNT)
            .forEach { assertFalse("${it.imageName} should be free", it.isPremium) }
        ContentCatalog.items.drop(ContentCatalog.FREE_DARSHAN_COUNT)
            .forEach { assertTrue("${it.imageName} should be premium", it.isPremium) }
    }

    @Test
    fun mantraChoices_sortedWithThreeFree() {
        val choices = ContentCatalog.mantraChoices
        assertEquals(19, choices.size)
        assertEquals(choices.map { it.deityEN }.sorted(), choices.map { it.deityEN })
        val free = choices.filterNot { it.isPremium }.map { it.id }.toSet()
        assertEquals(setOf("shiv", "ganesh", "krishna"), free)
    }

    @Test
    fun dailyItem_followsWeekdayDeity() {
        // 2026-06-29 = Monday (Shiva), 2026-06-24 = Wednesday (Ganesha), 2026-06-26 = Friday (Devi)
        assertTrue(ContentCatalog.dailyItem(LocalDate.of(2026, 6, 29)).imageName.contains("shiv"))
        assertTrue(ContentCatalog.dailyItem(LocalDate.of(2026, 6, 24)).imageName.contains("ganesh"))
        assertEquals(DeityCategory.SHAKTI, ContentCatalog.dailyItem(LocalDate.of(2026, 6, 26)).category)
    }

    @Test
    fun dailyItem_freeUserNeverGetsPremiumArt() {
        var d = LocalDate.of(2026, 1, 1)
        repeat(370) {
            assertFalse(ContentCatalog.dailyItem(d, hasPro = false).isPremium)
            d = d.plusDays(1)
        }
    }
}
