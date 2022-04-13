

pub contract Permissions {
    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()
    // emitted when permission updated
    pub event PermissionUpdated(resourceIdentifier: String, permissionIdentifier: String, key: UInt8, account: Address, whitelisted: Bool)

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/

    pub resource interface Tracker {
        pub fun hasPermission(_ key: UInt8, account: Address): Bool
        pub fun getPermissions(account: Address): [UInt8]
    }

    pub resource interface Setter {
        pub fun setPermission(_ key: UInt8, account: Address, whitelisted: Bool)
    }

    pub resource PermissionsKeeper: Setter, Tracker {
        access(self) let resouceIdentifier: String
        access(self) let permissionsIdentifier: String
        // permission map of all accounts
        access(self) var permissions: {UInt8: [Address]}

        init(resourceId: String, permissionId: String) {
            self.resouceIdentifier = resourceId
            self.permissionsIdentifier = permissionId
            self.permissions = {}
        }

        // set permission
        pub fun setPermission(_ key: UInt8, account: Address, whitelisted: Bool) {
            var isUpdated = false
            if let list = self.permissions[key] {
                if whitelisted && !list.contains(account) {
                    list.append(account)
                    isUpdated = true
                } else if !whitelisted && list.contains(account) {
                    for idx, addr in list {
                        if addr == account {
                            list.remove(at: idx)
                            isUpdated = true
                            break
                        }
                    }
                }
            } else if whitelisted {
                self.permissions[key] = [ account ]
                isUpdated = true
            }
            if isUpdated {
                emit PermissionUpdated(
                    resourceIdentifier: self.resouceIdentifier,
                    permissionIdentifier: self.permissionsIdentifier,
                    key: key,
                    account: account,
                    whitelisted: whitelisted
                )
            }
        }

        // get permission by key and account
        pub fun hasPermission(_ key: UInt8, account: Address): Bool {
            if let list = self.permissions[key] {
                return list.contains(account)
            }
            return false
        }

        // get all permissions of some account
        pub fun getPermissions(account: Address): [UInt8] {
            var permissions: [UInt8] = []
            for key in self.permissions.keys {
                let list = self.permissions[key]!
                if list.contains(account) {
                    permissions.append(key)
                }
            }
            return permissions
        }
    }

    // create a permission keerp resource
    pub fun createPermissionsKeeper(resourceId: String, permissionId: String): @PermissionsKeeper {
        return <- create PermissionsKeeper(resourceId: resourceId, permissionId: permissionId)
    }

    init() {
        emit ContractInitialized()
    }
}
