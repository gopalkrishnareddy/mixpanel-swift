//
//  MixpanelOptOutTests.swift
//  MixpanelDemoTests
//
//  Created by Zihe Jia on 3/27/18.
//  Copyright © 2018 Mixpanel. All rights reserved.
//

import XCTest
@testable import Mixpanel

class MixpanelOptOutTests: MixpanelBaseTests {
    func randomId() -> String
    {
        return String(format: "%08x%08x", arc4random(), arc4random())
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyAfterInitializedWithOptedOutYES()
    {
        mixpanel = Mixpanel.initialize(token: randomId(), optOutTracking: true)
        XCTAssertTrue(mixpanel.hasOptedOutTracking(), "When initialize with opted out flag set to YES, the current user should have opted out tracking")
    }
    
    func testNoTrackShouldEverBeTriggeredDuringInitializedWithOptedOutYES()
    {
        _ = stubTrack().andReturn(503)
        let launchOptions = [UIApplicationLaunchOptionsKey.remoteNotification:
            ["mp":["m":"the_message_id","c": "the_campaign_id",
                   "journey_id": 123456]
            ]]
        
        mixpanel = Mixpanel.initialize(token: randomId(), launchOptions: launchOptions, optOutTracking: true)
        waitForTrackingQueue()
        flushAndWaitForNetworkQueue()

        XCTAssert(mixpanel.flushInstance.flushRequest.networkConsecutiveFailures == 0,
                  "When initialize with opted out flag set to YES, no track should be ever triggered during ")
    }
    
    func testAutoTrackEventsShouldNotBeQueuedDuringInitializedWithOptedOutYES()
    {
        let launchOptions = [UIApplicationLaunchOptionsKey.remoteNotification:
            ["mp":["m":"the_message_id","c": "the_campaign_id",
                   "journey_id": 123456]
            ]]
        mixpanel = Mixpanel.initialize(token: randomId(), launchOptions: launchOptions, optOutTracking: true)
        waitForTrackingQueue()
        XCTAssertTrue(self.mixpanel.eventsQueue.count == 0, "When initialize with opted out flag set to YES, no event should be queued")
    }
    
    func testAutoTrackShouldBeTriggeredDuringInitializedWithOptedOutNO()
    {
        let launchOptions = [UIApplicationLaunchOptionsKey.remoteNotification:
            ["mp":["m":"the_message_id","c": "the_campaign_id",
                   "journey_id": 123456]
            ]]
        mixpanel = Mixpanel.initialize(token: randomId(), launchOptions: launchOptions, optOutTracking: false)
        waitForTrackingQueue()
        let e = mixpanel.eventsQueue.last!
        XCTAssertEqual((e["event"] as? String), "$app_open", "incorrect event name")
        let p = e["properties"] as? InternalProperties
        XCTAssertEqual((p!["journey_id"] as? NSNumber), 123456, "journey_id not equal")
    }
    
    func testOptInWillAddOptInEvent()
    {
        mixpanel.optInTracking()
        XCTAssertFalse(mixpanel.hasOptedOutTracking(), "The current user should have opted in tracking")
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.eventsQueue.count == 1, "When opted in, event queue should have one even(opt in) being queued")
        
        if mixpanel.eventsQueue.count > 0 {
            let event = mixpanel.eventsQueue.first
            XCTAssertEqual((event!["event"] as? String), "$opt_in", "When opted in, a track '$opt_in' should have been queued")
        }
        else {
            XCTAssertTrue(mixpanel.eventsQueue.count == 1, "When opted in, event queue should have one even(opt in) being queued")
        }
    }
    
    func testOptInTrackingForDistinctId()
    {
        mixpanel .optInTracking(distinctId: "testDistinctId")
        XCTAssertFalse(mixpanel.hasOptedOutTracking(), "The current user should have opted in tracking")
        waitForTrackingQueue()
        if mixpanel.eventsQueue.count > 0 {
            let event = mixpanel.eventsQueue.first
            XCTAssertEqual((event!["event"] as? String), "$opt_in", "When opted in, a track '$opt_in' should have been queued")
        }
        else {
            XCTAssertTrue(mixpanel.eventsQueue.count == 1, "When opted in, event queue should have one even(opt in) being queued")
        }
        
        XCTAssertEqual(mixpanel.distinctId, "testDistinctId", "mixpanel identify failed to set distinct id")
        XCTAssertEqual(mixpanel.people.distinctId, "testDistinctId", "mixpanel identify failed to set people distinct id")
        XCTAssertTrue(mixpanel.people.unidentifiedQueue.count == 0, "identify: should move records from unidentified queue")
    }
    
    func testOptInTrackingForDistinctIdAndWithEventProperties()
    {
        let now = Date()
        let testProperties: Properties = ["string": "yello",
            "number": 3,
            "date": now,
            "$app_version": "override"]
        mixpanel.optInTracking(distinctId: "testDistinctId", properties: testProperties)
        waitForTrackingQueue()
        let props = mixpanel.eventsQueue.last!["properties"] as? InternalProperties
        XCTAssertEqual(props!["string"] as? String, "yello")
        XCTAssertEqual(props!["number"] as? NSNumber, 3)
        XCTAssertEqual(props!["date"] as? Date, now)
        XCTAssertEqual(props!["$app_version"] as? String, "override", "reserved property override failed")
        
        if mixpanel.eventsQueue.count > 0 {
            let event = mixpanel.eventsQueue.first
            XCTAssertEqual((event!["event"] as? String), "$opt_in", "When opted in, a track '$opt_in' should have been queued")
        }
        else {
            XCTAssertTrue(mixpanel.eventsQueue.count == 1, "When opted in, event queue should have one even(opt in) being queued")
        }
        
        XCTAssertEqual(mixpanel.distinctId, "testDistinctId", "mixpanel identify failed to set distinct id")
        XCTAssertEqual(mixpanel.people.distinctId, "testDistinctId", "mixpanel identify failed to set people distinct id")
        XCTAssertTrue(mixpanel.people.unidentifiedQueue.count == 0, "identify: should move records from unidentified queue")
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyForMultipleInstances()
    {
        let mixpanel1 = Mixpanel.initialize(token: randomId(), optOutTracking: true)
        XCTAssertTrue(mixpanel1.hasOptedOutTracking(), "When initialize with opted out flag set to YES, the current user should have opted out tracking")
        
        let mixpanel2 = Mixpanel.initialize(token: randomId(), optOutTracking: false)
        XCTAssertFalse(mixpanel2.hasOptedOutTracking(), "When initialize with opted out flag set to NO, the current user should have opted in tracking")
        
        deleteOptOutSettings(mixpanelInstance: mixpanel1)
        deleteOptOutSettings(mixpanelInstance: mixpanel2)
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyAfterInitializedWithOptedOutNO()
    {
        mixpanel = Mixpanel.initialize(token: randomId(), optOutTracking: false)
        XCTAssertFalse(mixpanel.hasOptedOutTracking(), "When initialize with opted out flag set to NO, the current user should have opted out tracking")
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyByDefault()
    {
        mixpanel = Mixpanel.initialize(token: randomId())
        XCTAssertFalse(mixpanel.hasOptedOutTracking(), "By default, the current user should not opted out tracking")
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyForOptOut()
    {
        mixpanel.optOutTracking()
        XCTAssertTrue(mixpanel.hasOptedOutTracking(), "When optOutTracking is called, the current user should have opted out tracking")
    }
    
    func testHasOptOutTrackingFlagBeingSetProperlyForOptIn()
    {
        mixpanel.optOutTracking()
        XCTAssertTrue(mixpanel.hasOptedOutTracking(), "When optOutTracking is called, the current user should have opted out tracking")
        mixpanel.optInTracking()
        XCTAssertFalse(mixpanel.hasOptedOutTracking(), "When optOutTracking is called, the current user should have opted in tracking")
    }
    
    func testOptOutTrackingWillNotGenerateEventQueue()
    {
        mixpanel.optOutTracking()
        for i in 0..<50 {
            mixpanel.track(event: "event \(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.eventsQueue.count == 0, "When opted out, events should not be queued")
    }
    
    func testOptOutTrackingWillNotGeneratePeopleQueue()
    {
        mixpanel.optOutTracking()
        for i in 0..<50 {
            mixpanel.people.set(property: "p1", to: "\(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 0, "When opted out, events should not be queued")
    }
    
    func testOptOutTrackingWillSkipIdentify()
    {
        mixpanel.optOutTracking()
        mixpanel.identify(distinctId: "d1")
        //opt in again just to enable people queue
        mixpanel.optInTracking()
        for i in 0..<50 {
            mixpanel.people.set(property: "p1", to: "\(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.unidentifiedQueue.count == 50, "When opted out, calling identify should be skipped")
    }
    
    func testOptOutTrackingWillSkipAlias()
    {
        mixpanel.optOutTracking()
        mixpanel.createAlias("testAlias", distinctId: "aDistinctId")
        XCTAssertNotEqual(mixpanel.alias, "testAlias", "When opted out, alias should not be set")
    }
    
    func testOptOutTrackingRegisterSuperProperties()
    {
        let properties: Properties = ["p1": "a", "p2": 3, "p3": Date()]
        mixpanel.optOutTracking()
        mixpanel.registerSuperProperties(properties)
        waitForTrackingQueue()
        XCTAssertNotEqual(NSDictionary(dictionary: mixpanel.currentSuperProperties()),
                       NSDictionary(dictionary: properties),
                       "When opted out, register super properties should not be successful")
    }
    
    func testOptOutTrackingRegisterSuperPropertiesOnce()
    {
        let properties: Properties = ["p1": "a", "p2": 3, "p3": Date()]
        mixpanel.optOutTracking()
        mixpanel.registerSuperPropertiesOnce(properties)
        waitForTrackingQueue()
        XCTAssertNotEqual(NSDictionary(dictionary: mixpanel.currentSuperProperties()),
                          NSDictionary(dictionary: properties),
                          "When opted out, register super properties once should not be successful")
        
    }
    
    func testOptOutWilSkipTimeEvent()
    {
        mixpanel.optOutTracking()
        mixpanel.time(event: "400 Meters")
        mixpanel.track(event: "400 Meters")
        waitForTrackingQueue()
        XCTAssertNil(mixpanel.eventsQueue.last, "When opted out, this event should not be timed.")
    }
    
    func testOptOutTrackingWillPurgeEventQueue()
    {
        mixpanel.optInTracking()
        mixpanel.identify(distinctId: "d1")
        for i in 0..<50 {
            mixpanel.track(event: "event \(i)")
        }
        waitForTrackingQueue()
        //There will be an additional event for '$opt_in'
        XCTAssertTrue(mixpanel.eventsQueue.count == 51, "When opted in, events should have been queued")
        XCTAssertEqual(mixpanel.eventsQueue.first!["event"] as? String, "$opt_in", "incorrect optin event name")
        
        mixpanel.optOutTracking()
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.eventsQueue.count == 0, "When opted out, events should have been purged")
    }
    
    func testOptOutTrackingWillPurgePeopleQueue()
    {
        mixpanel.optInTracking()
        mixpanel.identify(distinctId: "d1")
        for i in 0..<50 {
            mixpanel.people.set(property: "p1", to: "\(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 50, "When opted in, people should have been queued")
        
        mixpanel.optOutTracking()
        waitForTrackingQueue()
        
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 2, "When opted out, people should have been purged except 'deleteUser' and 'clearCharges'")
    }
    
    func testOptOutTrackingWillDeleteUserAndClearCharges()
    {
        mixpanel.optInTracking()
        mixpanel.identify(distinctId: "d1")
        for i in 0..<50 {
            mixpanel.people.set(property: "p1", to: "\(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 50, "When opted in, people should have been queued")
        
        mixpanel.optOutTracking()
        waitForTrackingQueue()
        
        if mixpanel.people.peopleQueue.count == 2 {
            let people1 = mixpanel.people.peopleQueue[0]
            XCTAssertTrue(people1.keys.contains("$delete"), "When opted out, deleteUser should be in the queue")
            
            let people2 = mixpanel.people.peopleQueue[1]
            let set = people2["$set"] as! InternalProperties
            XCTAssertTrue(set.keys.contains("$transactions"), "When opted out, clearCharges should be in the queue")
        }
    }
    
    func testOptOutWillSkipFlushPeople()
    {
        mixpanel.optInTracking()
        mixpanel.identify(distinctId: "d1")
        for i in 0..<50 {
            mixpanel.people.set(property: "p1", to: "\(i)")
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 50, "When opted in, people queue should have been queued")
        
        let peopleQueue = mixpanel.people.peopleQueue
        mixpanel.optOutTracking()
        waitForTrackingQueue()
        
        mixpanel.people.peopleQueue = peopleQueue
        mixpanel.flush()
        waitForTrackingQueue()
        
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 50, "When opted out, people queue should not be flushed")
    }
    
    func testOptOutWillSkipFlushEvent()
    {
        mixpanel.optInTracking()
        mixpanel.identify(distinctId: "d1")
        for i in 0..<50 {
            mixpanel.track(event: "event \(i)")
        }
        
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.eventsQueue.count == 51, "When opted in, events should have been queued")
        
        let eventsQueue = mixpanel.eventsQueue
        mixpanel.optOutTracking()
        
        //In order to test if flush will be skipped, we have to create a fake eventsQueue since optOutTracking will clear eventsQueue.
        waitForTrackingQueue()
        mixpanel.eventsQueue = eventsQueue
        
        mixpanel.flush()
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.eventsQueue.count == 51, "When opted out, events should not be flushed")
    }
}