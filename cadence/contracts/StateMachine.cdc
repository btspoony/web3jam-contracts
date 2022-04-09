/**

Finite State Machine
*/

pub contract StateMachine {

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()
    // emitted when FSM created
    pub event FSMCreated(fsmId: UInt64, targetIdentifier: String, state: String)
    // emitted when state entered
    pub event FSMStateEntered(fsmOwner: Address, fsmId: UInt64, targetIdentifier: String, state: String)
    // emitted when state exited
    pub event FSMStateExited(fsmOwner: Address, fsmId: UInt64, targetIdentifier: String, state: String)

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/

    // An interface that every "verifier" must implement. 
    // A verifier is one of the options 
    // for example, a "time limit," or a "limited" number
    // All the current verifiers can be seen inside Web3JamVerifiers.cdc
    pub struct interface IVerifier {
        // A function every verifier must implement. 
        // Will have `assert`s in it to make sure
        // the user fits some criteria.
        access(account) fun verify(_ params: {String: AnyStruct})
    }

    // An interface that every "checker" must implement. 
    pub struct interface IChecker {
        access(account) fun check(_ params: {String: AnyStruct}): Bool
    }

    // An interface that every "action" must implement. 
    pub struct interface IAction {
        access(account) fun execute(_ params: {String: AnyStruct})
    }

    // record state changing log
    pub struct StateLog {
        pub let state: String
        pub let datetime: UFix64

        init(_ state: String, _ datetime: UFix64) {
            self.state = state
            self.datetime = datetime
        }
    }

    // result of FSM's checkNext method

    pub struct CheckResult {
        pub let changed: Bool
        pub let next: String?

        init(_ changed: Bool, _ next: String?) {
            self.changed = changed
            self.next = next
        }
    }

    // FSM transition
    pub struct StateTransition {
        pub let next: String
        pub let checker: {IChecker}
        
        init(next: String, checker: {IChecker}) {
            self.next = next
            self.checker = checker
        }
    }

    // FSM state definition
    pub struct StateDefinition {
        pub let name: String
        pub let transitions: [StateTransition]
        pub let enterActions: [{IAction}]
        pub let exitActions: [{IAction}]

        init(_ name: String, transitions: [StateTransition], enterActions: [{IAction}]?, exitActions: [{IAction}]?) {
            self.name = name
            self.transitions = transitions
            self.enterActions = enterActions ?? []
            self.exitActions = exitActions ?? []
        }
    }

    // Interface of a FSM
    pub resource interface IFiniteStateMachine {
        // ------ constants ------
        pub let targetIdentifier: String
        pub let states: {String: StateDefinition}

        // ------ varibles ------
        pub var currentState: String
        pub var lastState: String?
        access(account) var stateLogs: [StateLog]
        
        // ------ methods ------
        pub fun getStateLogs(): [StateLog]
        pub fun checkNext(_ params: {String: AnyStruct}): CheckResult
        access(account) fun executeNext(_ params: {String: AnyStruct})
    }

    // FSM resource
    pub resource FSM: IFiniteStateMachine {
        // ------ constants ------
        // traget identifier of FSM
        pub let targetIdentifier: String
        // states of FSM
        pub let states: {String: StateDefinition}

        // ------ varibles ------
        // current FSM state
        pub var currentState: String
        // last FSM state
        pub var lastState: String?
        // state logs
        access(account) var stateLogs: [StateLog]
        
        // ------ methods ------
        // check if fsm will go to next state 
        pub fun checkNext(_ params: {String: AnyStruct}): CheckResult {
            let stateDef = self.states[self.currentState] ?? panic("Current state is not defined.")

            var changed = false
            var next: String? = nil
            // check all transition
            for transition in stateDef.transitions {
                if transition.checker.check(params) {
                    changed = true
                    next = transition.next
                    break
                }
            }
            return CheckResult(changed, next)
        }

        // execute state machine to next state 
        access(account) fun executeNext(_ params: {String: AnyStruct}) {
            let ret = self.checkNext(params)
            assert(ret.changed, message: "Failed to execute and state is not chanaged.")
            assert(ret.next != nil, message: "Failed to get next state.")

            let currStateDef = self.states[self.currentState] ?? panic("Current state is not defined.")
            let nextStateDef = self.states[ret.next!] ?? panic("Next state is not defined.")
            let fsmOwner = self.owner!.address

            // exec current state exit actions
            for action in currStateDef.exitActions {
                action.execute(params)
            }
            // emit last Event
            emit FSMStateExited(fsmOwner: fsmOwner, fsmId: self.uuid, targetIdentifier: self.targetIdentifier, state: self.currentState)

            // exec next state exit actions
            for action in nextStateDef.enterActions {
                action.execute(params)
            }

            // emit next Event
            emit FSMStateEntered(fsmOwner: fsmOwner, fsmId: self.uuid, targetIdentifier: self.targetIdentifier, state: ret.next!)

            // update state
            self.lastState = self.currentState
            self.currentState = ret.next!
            // add to log
            self.stateLogs.append(StateLog(ret.next!, getCurrentBlock().timestamp))
        }

        pub fun getStateLogs(): [StateLog] {
            return self.stateLogs
        }

        // initialize
        init(_ targetIdentifier: String, states: {String: StateDefinition}, start: String) {
            pre {
                states[start] != nil: "There is no start state in states definition."
            }
            self.targetIdentifier = targetIdentifier
            self.states = states
            self.currentState = start
            self.lastState = nil
            self.stateLogs = [StateLog(start, getCurrentBlock().timestamp)]

            // emit created event
            emit FSMCreated(fsmId: self.uuid, targetIdentifier: targetIdentifier, state: start)
        }
    }

    // create new FSM resource
    pub fun createFSM(_ targetIdentifier: String, states: {String: StateDefinition}, start: String): @FSM {
        return <- create FSM(targetIdentifier, states: states, start: start)
    }

    // ------- utility methods -------

    // convert struct array to a typed dictionary
    access(account) fun buildTypedStructs(_ array: [AnyStruct]): {String: [AnyStruct]} {
        let typed: {String: [AnyStruct]} = {}
        for one in array {
            let identifier = one.getType().identifier
            if typed[identifier] == nil {
                typed[identifier] = [one]
            } else {
                typed[identifier]!.append(one)
            }
        }
        return typed
    }

    init() {
        emit ContractInitialized()
    }
}