/// Módulo centralizado de eventos
module sui_messenger::events;

use std::string::String;
use sui::event;

// ==================== EVENTOS ====================

public struct MessageSent has copy, drop {
    message_id: ID,
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    seal_policy_id: Option<ID>,
    content_hash: vector<u8>,
    timestamp: u64,
}

public struct MessageReadSimple has copy, drop {
    message_id: ID,
    reader: address,
    timestamp: u64,
}

public struct GroupCreated has copy, drop {
    group_id: ID,
    admin: address,
    member_count: u64,
    timestamp: u64,
}

public struct GroupMessageSent has copy, drop {
    group_id: ID,
    sender: address,
    timestamp: u64,
}

// ==================== EMITTERS ====================

public(package) fun emit_message_sent(
    message_id: ID,
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    seal_policy_id: Option<ID>,
    content_hash: vector<u8>,
    timestamp: u64,
) {
    event::emit(MessageSent {
        message_id,
        sender,
        recipient,
        walrus_blob_id,
        seal_policy_id,
        content_hash,
        timestamp,
    });
}

public(package) fun emit_message_read_simple(message_id: ID, reader: address, timestamp: u64) {
    event::emit(MessageReadSimple {
        message_id,
        reader,
        timestamp,
    });
}

public(package) fun emit_group_created(
    group_id: ID,
    admin: address,
    member_count: u64,
    timestamp: u64,
) {
    event::emit(GroupCreated {
        group_id,
        admin,
        member_count,
        timestamp,
    });
}

public(package) fun emit_group_message_sent(group_id: ID, sender: address, timestamp: u64) {
    event::emit(GroupMessageSent {
        group_id,
        sender,
        timestamp,
    });
}
