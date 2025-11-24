module sui_messenger::chat;

use sui::event;
use sui::table::{Self, Table};
use sui::vec_map::{Self, VecMap};

const EChatAlreadyExists: u64 = 0;

public struct ChatRegistry has key {
    id: UID,
    chats: Table<vector<u8>, ID>,
}

public struct Chat has key, store {
    id: UID,
    participants: vector<address>,
    unread_counts: VecMap<address, u64>,
    message_count: u64,
}

public struct ChatCreated has copy, drop {
    id: ID,
    participants: vector<address>,
}

fun init(ctx: &mut TxContext) {
    let registry = ChatRegistry {
        id: object::new(ctx),
        chats: table::new(ctx),
    };
    transfer::share_object(registry);
}

public fun create_chat(
    registry: &mut ChatRegistry,
    other_party: address,
    ctx: &mut TxContext,
): Chat {
    let sender = tx_context::sender(ctx);
    let mut participants = vector::empty();
    vector::push_back(&mut participants, sender);
    vector::push_back(&mut participants, other_party);

    sort_addresses(&mut participants);
    let key = participants_key(&participants);

    assert!(!table::contains(&registry.chats, key), EChatAlreadyExists);

    let mut unread_counts = vec_map::empty();
    vec_map::insert(&mut unread_counts, sender, 0);
    vec_map::insert(&mut unread_counts, other_party, 0);

    let chat = Chat {
        id: object::new(ctx),
        participants: participants,
        unread_counts,
        message_count: 0,
    };

    table::add(&mut registry.chats, key, object::id(&chat));

    chat
}

public fun share_chat(chat: Chat) {
    event::emit(ChatCreated {
        id: object::id(&chat),
        participants: *&chat.participants,
    });
    transfer::share_object(chat);
}

public fun mark_as_read(chat: &mut Chat, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    if (vec_map::contains(&chat.unread_counts, &sender)) {
        let count = vec_map::get_mut(&mut chat.unread_counts, &sender);
        *count = 0;
    }
}

public(package) fun increment_unread(chat: &mut Chat, recipient: address) {
    chat.message_count = chat.message_count + 1;
    if (vec_map::contains(&chat.unread_counts, &recipient)) {
        let count = vec_map::get_mut(&mut chat.unread_counts, &recipient);
        *count = *count + 1;
    }
}

public fun is_participant(chat: &Chat, addr: address): bool {
    vector::contains(&chat.participants, &addr)
}

public fun chat_exists(
    registry: &ChatRegistry,
    participant_a: address,
    participant_b: address,
): bool {
    let mut participants = vector::empty();
    vector::push_back(&mut participants, participant_a);
    vector::push_back(&mut participants, participant_b);
    sort_addresses(&mut participants);
    table::contains(&registry.chats, participants_key(&participants))
}

fun sort_addresses(addrs: &mut vector<address>) {
    let len = vector::length(addrs);
    let mut i = 0;
    while (i < len) {
        let mut j = i + 1;
        while (j < len) {
            let addr_i = *vector::borrow(addrs, i);
            let addr_j = *vector::borrow(addrs, j);
            if (compare_address(addr_i, addr_j) == 2) {
                vector::swap(addrs, i, j);
            };
            j = j + 1;
        };
        i = i + 1;
    };
}

fun compare_address(a: address, b: address): u8 {
    use sui::bcs;
    let bytes_a = bcs::to_bytes(&a);
    let bytes_b = bcs::to_bytes(&b);
    let len = vector::length(&bytes_a);
    let mut i = 0;
    while (i < len) {
        let byte_a = *vector::borrow(&bytes_a, i);
        let byte_b = *vector::borrow(&bytes_b, i);
        if (byte_a < byte_b) return 1;
        if (byte_a > byte_b) return 2;
        i = i + 1;
    };
    0
}

fun participants_key(participants: &vector<address>): vector<u8> {
    use sui::bcs;
    bcs::to_bytes(participants)
}
