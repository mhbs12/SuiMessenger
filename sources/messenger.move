module sui_messenger::messenger;

use std::string;
use sui::clock::{Self, Clock};
use sui_messenger::chat::{Self, Chat, ChatRegistry};
use sui_messenger::events;
use sui_messenger::message::{Self, Message};

// ==================== ERRORS ====================
const ENotRecipient: u64 = 1;
const ENotParticipant: u64 = 2;
const EAlreadyRead: u64 = 3;

// ==================== ENVIAR MENSAGEM (Chat Existente) ====================

/// Envia mensagem para um chat existente
entry fun send_message(
    chat: &mut Chat,
    recipient: address,
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    seal_policy_id: Option<ID>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    internal_send_message(
        chat,
        recipient,
        walrus_blob_id,
        content_hash,
        encrypted_metadata,
        seal_policy_id,
        clock,
        ctx,
    );
}

// ==================== ENVIAR MENSAGEM (Novo Chat) ====================

/// Cria chat e envia mensagem em uma única transação
entry fun create_chat_and_send(
    registry: &mut ChatRegistry,
    recipient: address,
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    seal_policy_id: Option<ID>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Cria o chat (ainda não compartilhado)
    let mut chat = chat::create_chat(registry, recipient, ctx);

    // Envia a mensagem
    internal_send_message(
        &mut chat,
        recipient,
        walrus_blob_id,
        content_hash,
        encrypted_metadata,
        seal_policy_id,
        clock,
        ctx,
    );

    // Compartilha o chat
    chat::share_chat(chat);
}

// ==================== LÓGICA INTERNA ====================

fun internal_send_message(
    chat: &mut Chat,
    recipient: address,
    walrus_blob_id: vector<u8>,
    content_hash: vector<u8>,
    encrypted_metadata: vector<u8>,
    seal_policy_id: Option<ID>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    assert!(chat::is_participant(chat, sender), ENotParticipant);

    // 1. Auto-Mark as Read para o REMETENTE (se ele tinha mensagens não lidas)
    chat::mark_as_read(chat, ctx);

    // 2. Incrementa Unread para o DESTINATÁRIO
    chat::increment_unread(chat, recipient);

    // 3. Cria o objeto Message
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

    // 4. Emite Evento
    events::emit_message_sent(
        message_id,
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        seal_policy_id,
        content_hash,
        now,
    );

    // 5. Transfere Message para o destinatário
    transfer::public_transfer(message, recipient);
}

// ==================== LEITURA ====================

/// Marca mensagem como lida (e atualiza o Chat)
entry fun mark_as_read(message: &mut Message, chat: &mut Chat, clock: &Clock, ctx: &mut TxContext) {
    let reader = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    assert!(message::recipient(message) == reader, ENotRecipient);
    assert!(!message::is_read(message), EAlreadyRead);

    // Marca mensagem como lida
    message::mark_as_read(message);

    // Zera contador no Chat
    chat::mark_as_read(chat, ctx);

    // Emite evento
    events::emit_message_read_simple(
        object::uid_to_inner(message::id(message)),
        reader,
        now,
    );
}

// ==================== SEAL ACCESS CONTROL ====================

/// SEAL approval function: Allows the message sender to decrypt their own sent messages
/// This is called by SEAL key servers during decryption to verify access rights
public fun seal_approve_sender(_message_id: vector<u8>, chat: &Chat, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    // Verify caller is a participant in the chat (sender or receiver)
    assert!(chat::is_participant(chat, caller), ENotParticipant);
    // SEAL convention: function must return () to indicate approval
}

/// SEAL approval function: Allows the message recipient to decrypt received messages
/// This is called by SEAL key servers during decryption to verify access rights
public fun seal_approve_receiver(_message_id: vector<u8>, chat: &Chat, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    // Verify caller is a participant in the chat (sender or receiver)
    assert!(chat::is_participant(chat, caller), ENotParticipant);
    // SEAL convention: function must return () to indicate approval
}
