/**

Web3Jam contract interfaces or structs
*/

import StateMachine from "./StateMachine.cdc"

pub contract Web3JamInterfaces {

    /**   ___  ____ ____ _ _  _ _ ___ _ ____ _  _ 
       *  |  \ |___ |___ | |\ | |  |  | |  | |\ | 
        * |__/ |___ |    | | \| |  |  | |__| | \| 
         *****************************************/

    // enum for Web3Jam HQ whitelist
    pub enum WhiteListKey: UInt8 {
        pub case administrator
        pub case fullControl
    }

    // enum for campaign tag
    pub enum TagType: UInt8 {
        pub case projectScope
        pub case role
    }

    // a wrapper to contain a address, campaign id
    pub struct CampaignIdentifier {
        pub let campaignId: UInt64
        pub let address: Address

        init (
            _ address: Address,
            _ campaignId: UInt64
        ) {
            self.address = address
            self.campaignId = campaignId
        }
    }

    // a wrapper to contain a address, campaign id, project id
    pub struct ProjectIdentifier {
        pub let campaign: CampaignIdentifier
        pub let projectId: UInt64

        init (
            _ address: Address,
            _ campaignId: UInt64,
            _ projectId: UInt64
        ) {
            self.campaign = CampaignIdentifier(address, campaignId)
            self.projectId = projectId
        }
    }

    // Sponsor
    pub struct Sponsor {
        // sponsor information
        pub let name: String
        pub var description: String
        pub var thumbnail: String

        init(name: String, description: String, thumbnail: String) {
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
        }
    }

    // Tag
    pub struct Tag {
        pub var name: String
        pub var color: String

        init(name: String, color: String) {
            self.name = name
            self.color = color
        }
    }

    // Award
    pub struct Award {
        pub let projectId: UInt64
        pub let prizeTypeId: UInt64
        pub var claimed: Bool
        pub var claimedNFTId: UInt64?

        init(_ projectId: UInt64, _ prizeTypeId: UInt64) {
            self.projectId = projectId
            self.prizeTypeId = prizeTypeId
            self.claimed = false
            self.claimedNFTId = nil
        }

        pub fun setClaimed(_ nftId: UInt64) {
            self.claimed = true
            self.claimedNFTId = nftId
        }
    }

    /**    _ _  _ ___ ____ ____ ____ ____ ____ ____ 
       *   | |\ |  |  |___ |__/ |___ |__| |    |___ 
        *  | | \|  |  |___ |  \ |    |  | |___ |___ 
         *******************************************/

    // Web3JamHQ Private Interface
    pub resource interface Web3JamHQPrivate {
        // Account Setters
        access(account) fun setWhitelisted(_ key: WhiteListKey, account: Address, whitelisted: Bool)
    }

    // Web3JamHQ Public Interface
    pub resource interface Web3JamHQPublic {
        // Public Getters
        pub fun getOpeningCampaignIDs(): [CampaignIdentifier]
        pub fun isWhitelisted(_ key: WhiteListKey, account: Address): Bool
        // Account Getters
        access(account) fun borrowHQPrivateRef(): &AnyResource{Web3JamHQPrivate}
    }

    pub resource interface CampaignsControllerPrivate {
        // Public Setter
        pub fun createCompaign(
            name: String,
            description: String,
            image: String,
            imageHeader: String?,
            guideUrl: String,
            registerUrl: String?,
            startTime: UFix64?,
            endTime: UFix64,
            sponsors: [Web3JamInterfaces.Sponsor],
            projectTags: [Web3JamInterfaces.Tag],
            roleTags: [Web3JamInterfaces.Tag],
            _ extensions: {String: AnyStruct}
        ): UInt64
        // Account Setters
    }

    // CampaignsController Public Interface
    pub resource interface CampaignsControllerPublic {
        // Public Getters
        pub fun getIDs(): [UInt64]
    }

    pub resource interface CampaignPrivate {
        // Public Setter
        pub fun addSponsors(sponsorsToAdd: [Sponsor])
        pub fun addTags(type: TagType, tagsToAdd: [Tag])
    }

    pub resource interface CampaignPublic {
        // Public Getters
        pub fun getCurrentState(): String

        pub fun getSponsor(idx: UInt64): Sponsor?
        pub fun getAvailableSponsors(): [Sponsor]
        pub fun getTag(type: TagType,  idx: UInt64): Tag?
        pub fun getAvailableTags(type: TagType): [Tag]
    }

}