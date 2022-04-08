/**

Web3Jam contract interfaces or structs
*/

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
    pub struct CampaignIdentitier {
        pub let id: UInt64
        pub let address: Address

        init (
            _ id: UInt64,
            _ address: Address
        ) {
            self.id = id
            self.address = address
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
        pub let type: Web3JamInterfaces.TagType
        pub var name: String
        pub var color: String

        init(type: Web3JamInterfaces.TagType, name: String, color: String) {
            self.type = type
            self.name = name
            self.color = color
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
        pub fun getOpeningCampaignIDs(): [CampaignIdentitier]
        pub fun isWhitelisted(_ key: WhiteListKey, account: Address): Bool
        // Account Getters
        access(account) fun borrowHQPrivateRef(): &AnyResource{Web3JamHQPrivate}
    }

    // CampaignsController Public Interface
    pub resource interface CampaignsControllerPublic {
        // Public Getters
        pub fun getIDs(): [UInt64]
        pub fun getSponsor(idx: UInt64): Sponsor
        pub fun getAvailableSponsors(): [Sponsor]
        pub fun getTag(idx: UInt64): Tag
        pub fun getAvailableTags(type: TagType): [Tag]
    }

}