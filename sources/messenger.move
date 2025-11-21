/// Módulo principal de envio e leitura de mensagens
module sui_messenger::messenger;

use std::string;
use sui::clock::{Self, Clock};
use sui_messenger::events;
use sui_messenger::inbox;
use sui_messenger::message::{Self, Message};

// ==================== ERRORS ====================

const ENotRecipient: u64 = 1;

const EAlreadyRead: u64 = 3;

// ==================== ENVIAR MENSAGEM ====================

/// Envia mensagem criptografada
entry fun send_message(
    recipient: address,
    recipient_inbox: &mut inbox::Inbox, // [NEW] Inbox do destinatário
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    seal_policy_id: Option<ID>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // [NEW] Atualiza Inbox
    assert!(inbox::owner(recipient_inbox) == recipient, ENotRecipient);
    inbox::increment_message_count(recipient_inbox);

    let message = message::new_message(
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        encrypted_metadata,
        seal_policy_id,
        now,
        ctx,
    );

    let message_id = object::id(&message);

    // Emite evento
    events::emit_message_sent(
        message_id,
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        seal_policy_id,
        content_hash,
        now,
    );

    // Transfere para destinatário
    transfer::public_transfer(message, recipient);
}

// ==================== LEITURA ====================

/// Marca mensagem como lida
entry fun mark_as_read(
    message: &mut Message,
    reader_inbox: &mut inbox::Inbox, // [NEW] Inbox do leitor
    clock: &Clock,
    ctx: &TxContext,
) {
    let reader = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    assert!(message::recipient(message) == reader, ENotRecipient);
    assert!(!message::is_read(message), EAlreadyRead);

    // Marca como lida
    message::mark_as_read(message);

    // [NEW] Atualiza Inbox
    assert!(inbox::owner(reader_inbox) == reader, ENotRecipient);
    inbox::decrement_unread_count(reader_inbox);

    // Emite evento
    events::emit_message_read_simple(
        object::uid_to_inner(message::id(message)),
        reader,
        now,
    );
}

// ==================== GETTERS ====================

/// Retorna informações da mensagem
public fun get_message_info(
    message: &Message,
): (
    address, // sender
    address, // recipient
    u64, // created_at
    u64, // created_at
    bool, // is_read
) {
    (
        message::sender(message),
        message::recipient(message),
        message::created_at(message),
        message::created_at(message),
        message::is_read(message),
    )
}
