/// Módulo centralizado de eventos
module sui_messenger::events;

use sui::event;


// ==================== EVENTOS ====================

public struct MessageSent has copy, drop {
    message_id: ID,
    sender: address,
    recipient: address,
    timestamp: u64,
    expires_at: u64,
}

public struct MessageRead has copy, drop {
    message_id: ID,
    reader: address,
    timestamp: u64,
    proof_hash: vector<u8>,
}

public struct MessageReadSimple has copy, drop {
    message_id: ID,
    reader: address,
    timestamp: u64,
}

public struct MessageBurned has copy, drop {
    message_id: ID,
    burner: address,
    timestamp: u64,
    reason: u8, // 0=manual, 1=expired, 2=auto
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
    timestamp: u64,
    expires_at: u64,
) {
    event::emit(MessageSent {
        message_id,
        sender,
        recipient,
        timestamp,
        expires_at,
    });
}

public(package) fun emit_message_read(
    message_id: ID,
    reader: address,
    timestamp: u64,
    proof_hash: vector<u8>,
) {
    event::emit(MessageRead {
        message_id,
        reader,
        timestamp,
        proof_hash,
    });
}

public(package) fun emit_message_read_simple(message_id: ID, reader: address, timestamp: u64) {
    event::emit(MessageReadSimple {
        message_id,
        reader,
        timestamp,
    });
}

public(package) fun emit_message_burned(
    message_id: ID,
    burner: address,
    timestamp: u64,
    reason: u8,
) {
    event::emit(MessageBurned {
        message_id,
        burner,
        timestamp,
        reason,
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

// ==================== CONSTANTS ====================

public fun burn_reason_manual(): u8 { 0 }

public fun burn_reason_expired(): u8 { 1 }

public fun burn_reason_auto(): u8 { 2 }
