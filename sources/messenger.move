module sui_messenger::messenger;

use std::string;
use sui::clock::{Self, Clock};
use sui_messenger::chat::{Self, Chat, ChatRegistry};
use sui_messenger::events;
use sui_messenger::message::{Self, Message};

const ENotRecipient: u64 = 1;
const ENotParticipant: u64 = 2;
const EAlreadyRead: u64 = 3;

entry fun send_message(
    chat: &mut Chat,
    recipient: address,
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    internal_send_message(
        chat,
        recipient,
        walrus_blob_id,
        content_hash,
        encrypted_metadata,
        clock,
        ctx,
    );
}

entry fun create_chat(registry: &mut ChatRegistry, recipient: address, ctx: &mut TxContext) {
    let chat = chat::create_chat(registry, recipient, ctx);
    chat::share_chat(chat);
}

fun internal_send_message(
    chat: &mut Chat,
    recipient: address,
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    assert!(chat::is_participant(chat, sender), ENotParticipant);

    chat::mark_as_read(chat, ctx);
    chat::increment_unread(chat, recipient);

    let message = message::new_message(
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        encrypted_metadata,
        now,
        ctx,
    );

    let message_id = object::id(&message);

    events::emit_message_sent(
        message_id,
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        content_hash,
        now,
    );

    transfer::public_transfer(message, recipient);
}

entry fun mark_as_read(message: &mut Message, chat: &mut Chat, clock: &Clock, ctx: &mut TxContext) {
    let reader = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    assert!(message::recipient(message) == reader, ENotRecipient);
    assert!(!message::is_read(message), EAlreadyRead);

    message::mark_as_read(message);
    chat::mark_as_read(chat, ctx);

    events::emit_message_read_simple(
        object::uid_to_inner(message::id(message)),
        reader,
        now,
    );
}

/// SEAL approval: allows participants to decrypt messages
public fun seal_approve_sender(_message_id: vector<u8>, chat: &Chat, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    assert!(chat::is_participant(chat, caller), ENotParticipant);
}

/// SEAL approval: allows participants to decrypt messages
public fun seal_approve_receiver(_message_id: vector<u8>, chat: &Chat, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    assert!(chat::is_participant(chat, caller), ENotParticipant);
}
