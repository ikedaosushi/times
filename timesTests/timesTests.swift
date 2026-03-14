import Testing
@testable import times

@Test func testUserSettingsLogicalDate() {
    let settings = UserSettings(dayBoundaryHour: 5)
    let calendar = Calendar.current

    // 3:00 AM on March 12 should be logical date March 11
    let earlyMorning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 12, hour: 3))!
    let logicalDate = settings.logicalDate(for: earlyMorning)
    let expected = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2026, month: 3, day: 11))!)
    #expect(logicalDate == expected)

    // 10:00 AM on March 12 should be logical date March 12
    let morning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 12, hour: 10))!
    let logicalDate2 = settings.logicalDate(for: morning)
    let expected2 = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2026, month: 3, day: 12))!)
    #expect(logicalDate2 == expected2)
}

@Test func testPostHasLocation() {
    let post = Post(text: "テスト")
    #expect(!post.hasLocation)

    let postWithLocation = Post(text: "テスト", latitude: 35.6812, longitude: 139.7671, locationName: "東京駅")
    #expect(postWithLocation.hasLocation)
}

@Test func testChannelInit() {
    let channel = Channel(name: "main", sortOrder: 0)
    #expect(channel.name == "main")
    #expect(channel.sortOrder == 0)
    #expect(channel.sortedPosts.isEmpty)
}

@Test func testTagClose() {
    let tag = Tag(name: "旅行")
    #expect(tag.isActive)
    #expect(tag.endDate == nil)

    tag.close()
    #expect(!tag.isActive)
    #expect(tag.endDate != nil)
}
