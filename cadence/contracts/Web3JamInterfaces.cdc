/**

Web3Jam contract interfaces or structs
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import StateMachine from "./StateMachine.cdc"

pub contract Web3JamInterfaces {

    /**   ___  ____ ____ _ _  _ _ ___ _ ____ _  _ 
       *  |  \ |___ |___ | |\ | |  |  | |  | |\ | 
        * |__/ |___ |    | | \| |  |  | |__| | \| 
         *****************************************/

    // enum for Web3Jam HQ whitelist
    pub enum PermissionKey: UInt8 {
        pub case administrator
        pub case campaignsControllerWhitelist
        pub case campaignsControllerMaintainer
        pub case campaignMaintainer
        pub case campaignParticipant
        pub case campaignJudge
        pub case projectMaintainer
        pub case projectMember
        pub case projectJudge
    }

    // enum for campaign tag
    pub enum TagType: UInt8 {
        pub case projectScope
        pub case role
    }

    // a wrapper to contain a address, campaign id
    pub struct CampaignIdentifier {
        pub let controller: Address
        pub let campaignId: UInt64

        init (
            _ controller: Address,
            _ campaignId: UInt64
        ) {
            self.controller = controller
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

    // Prize Unit
    pub struct PrizeUnit {
        pub let currency: String
        pub let amount: Fix64

        init(currency: String, amount: Fix64) {
            self.currency = currency
            self.amount = amount
        }
    }

    // Prize
    pub struct PrizeInfo {
        pub let name: String
        pub let description: String
        pub let image: String

        pub let values: [PrizeUnit]
        pub let isWithNFT: Bool

        init(name: String, desc: String, image: String, values: [PrizeUnit], withNFT: Bool) {
            self.name = name
            self.description = desc
            self.image = image
            self.values = values
            self.isWithNFT = withNFT
        }
    }

    // Award
    pub struct Award {
        pub let project: ProjectIdentifier
        pub let prizeName: String
        pub var claimed: Bool
        pub var claimedNFTId: UInt64?

        init(_ project: ProjectIdentifier, _ prizeName: String) {
            self.project = project
            self.prizeName = prizeName
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
        access(account) fun setWhitelisted(_ key: PermissionKey, account: Address, whitelisted: Bool)
    }

    // Web3JamHQ Public Interface
    pub resource interface Web3JamHQPublic {
        // Public Getters
        pub fun getOpeningCampaignIDs(): [CampaignIdentifier]
        pub fun isWhitelisted(_ key: PermissionKey, account: Address): Bool
        // Account Getters
        access(account) fun borrowHQPrivateRef(): &AnyResource{Web3JamHQPrivate}
    }

    pub resource interface CampaignsControllerPrivate {
        // Public Setter
        pub fun createCompaign(
            creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>,
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
        pub fun setMaintainer(account: Address, whitelisted: Bool)

        // Account Setters
    }

    // CampaignsController Public Interface
    pub resource interface CampaignsControllerPublic {
        // Public Getters
        pub fun getIDs(): [UInt64]
        pub fun getCampaign(campaignID: UInt64): &{CampaignPublic, MetadataViews.Resolver}?

        pub fun isMaintainer(_ account: Address): Bool
    }

    pub resource interface Web3JamPermissionTracker {
        pub fun hasPermission(_ key: PermissionKey, account: Address): Bool
    }

    pub resource interface CampaignMaintainer {
        // Public Setter
        pub fun addSponsors(sponsorsToAdd: [Sponsor])
        pub fun addTags(type: TagType, tagsToAdd: [Tag])

        pub fun updateBasics(name: String, description: String, image: String, imageHeader: String?, guideUrl: String, registerUrl: String?)
        pub fun upsertPrize(prize: PrizeInfo)
    }

    pub resource interface CampaignParticipant {
        // Public Setter
        pub fun createProject(
            creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>,
            name: String,
            description: String,
            image: String?,
            tags: [Web3JamInterfaces.Tag],
            _ extensions: {String: AnyStruct}
        ): &{ProjectPublic, MetadataViews.Resolver}
    }

    pub resource interface CampaignJudge {
        // Public Getters

        // Public Setter

    }

    pub resource interface CampaignPublic {
        // Public Getters
        pub fun getIDs(): [UInt64]
        pub fun getProject(projectID: UInt64): &{ProjectPublic, MetadataViews.Resolver}?
        pub fun getPrizes(): [PrizeInfo]

        pub fun getCurrentState(): String

        // permission check
        pub fun hasJoined(account: Address): Bool

        // contents
        pub fun getSponsor(idx: UInt64): Sponsor?
        pub fun getAvailableSponsors(): [Sponsor]
        pub fun getTag(type: TagType,  idx: UInt64): Tag?
        pub fun getAvailableTags(type: TagType): [Tag]

        // Account Setters
        access(account) fun participate(account: Address)
        access(account) fun joinProject(account: Address, projectID: UInt64)
    }

    pub resource interface ProjectMaintainer {
        // Public Setter

    }

    pub resource interface ProjectMember {
        // Public Getters

        // Public Setter

    }

    pub resource interface ProjectJudge {
        // Public Getters

        // Public Setter

    }

    pub resource interface ProjectPublic {
        // Public Getters
        pub fun getCampaign(): &{CampaignPublic, MetadataViews.Resolver}
        pub fun getCurrentState(): String

        // permission check
        pub fun hasJoined(account: Address): Bool
    }

    pub resource interface AccessVoucherPrivate {
        // Public Setter
        pub fun participateCampaign(campaign: &{CampaignPublic, MetadataViews.Resolver}) 
        pub fun applyForProject(project: &{ProjectPublic, MetadataViews.Resolver})
    }

    pub resource interface AccessVoucherPublic {
        // Public Getters

        // Account Setters

    }

}