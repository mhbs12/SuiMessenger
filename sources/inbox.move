/// Módulo de gerenciamento de inbox
module sui_messenger::inbox;

//=================== ESTRUTURAS ====================
/// Inbox de cada usuário
public struct Inbox has key {
    id: UID,
    owner: address,
    message_count: u64,
    unread_count: u64,
}

// ==================== ERRORS ====================

// ==================== FUNÇÕES PÚBLICAS ====================

/// Cria novo inbox para usuário
entry fun create_inbox(ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);

    let inbox = Inbox {
        id: object::new(ctx),
        owner: sender,
        message_count: 0,
        unread_count: 0,
    };

    transfer::share_object(inbox);
}

/// Incrementa contador de mensagens
public(package) fun increment_message_count(inbox: &mut Inbox) {
    inbox.message_count = inbox.message_count + 1;
    inbox.unread_count = inbox.unread_count + 1;
}

/// Decrementa contador de não lidas
public(package) fun decrement_unread_count(inbox: &mut Inbox) {
    if (inbox.unread_count > 0) {
        inbox.unread_count = inbox.unread_count - 1;
    }
}

// ==================== GETTERS ====================

public fun owner(inbox: &Inbox): address {
    inbox.owner
}

public fun message_count(inbox: &Inbox): u64 {
    inbox.message_count
}

public fun unread_count(inbox: &Inbox): u64 {
    inbox.unread_count
}

public fun get_stats(inbox: &Inbox): (u64, u64) {
    (inbox.message_count, inbox.unread_count)
}

// ==================== TESTES ====================

#[test_only]
public fun create_for_testing(ctx: &mut TxContext): Inbox {
    Inbox {
        id: object::new(ctx),
        owner: tx_context::sender(ctx),
        message_count: 0,
        unread_count: 0,
    }
}

#[test]
fun test_increment_counters() {
    use sui::test_scenario;

    let owner = @0xA;
    let mut scenario = test_scenario::begin(owner);

    {
        let mut inbox = create_for_testing(test_scenario::ctx(&mut scenario));

        increment_message_count(&mut inbox);
        assert!(message_count(&inbox) == 1, 0);
        assert!(unread_count(&inbox) == 1, 0);

        decrement_unread_count(&mut inbox);
        assert!(unread_count(&inbox) == 0, 0);

        let Inbox { id, owner: _, message_count: _, unread_count: _ } = inbox;
        object::delete(id);
    };

    test_scenario::end(scenario);
}
