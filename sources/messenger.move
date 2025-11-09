/// Módulo principal de envio e leitura de mensagens
module sui_messenger::messenger;

use sui_messenger::events;
use sui_messenger::message::{Self, Message};
use sui_messenger::verification;
use std::string;
use sui::clock::{Self, Clock};

// ==================== ERRORS ====================

const ENotRecipient: u64 = 1;
const ENotSender: u64 = 2;
const EAlreadyRead: u64 = 3;
const EMessageExpired: u64 = 4;
const EAlreadyBurned: u64 = 5;
const EInvalidProof: u64 = 6;

// ==================== ENVIAR MENSAGEM ====================

/// Envia mensagem criptografada
entry fun send_message(
    recipient: address,
    walrus_blob_id: vector<u8>,
    encrypted_metadata: vector<u8>,
    ttl_seconds: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    let message = message::new_message(
        sender,
        recipient,
        string::utf8(walrus_blob_id),
        encrypted_metadata,
        now,
        now + ttl_seconds,
        ctx,
    );

    let message_id = object::id(&message);

    // Emite evento
    events::emit_message_sent(
        message_id,
        sender,
        recipient,
        now,
        now + ttl_seconds,
    );

    // Transfere para destinatário
    transfer::transfer(message, recipient);
}

// ==================== LEITURA COM ZK PROOF ====================

/// Marca mensagem como lida com ZK proof (privacidade total)
entry fun mark_as_read_private(
    message: &mut Message,
    zk_proof: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let reader = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    assert!(message::recipient(message) == reader, ENotRecipient);
    assert!(!message::is_read(message), EAlreadyRead);
    assert!(!message::is_expired(message, now), EMessageExpired);
    assert!(!message::is_burned(message), EAlreadyBurned);

    // Valida ZK proof
    let proof_valid = verification::verify_read_proof(
        &zk_proof,
        object::uid_to_bytes(message::id(message)),
        reader,
    );
    assert!(proof_valid, EInvalidProof);

    // Marca como lida
    message::mark_as_read(message, zk_proof);

    // Emite evento (só hash do proof, privacidade preservada)
    events::emit_message_read(
        object::uid_to_inner(message::id(message)),
        reader,
        now,
        verification::hash_proof(&zk_proof),
    );
}

/// Marca mensagem como lida SEM proof (modo simples)
entry fun mark_as_read_simple(message: &mut Message, clock: &Clock, ctx: &mut TxContext) {
    let reader = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    assert!(message::recipient(message) == reader, ENotRecipient);
    assert!(!message::is_read(message), EAlreadyRead);
    assert!(!message::is_expired(message, now), EMessageExpired);

    // Marca como lida sem proof
    message::mark_as_read(message, vector::empty());

    // Emite evento simples
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
    u64, // expires_at
    bool, // is_read
) {
    (
        message::sender(message),
        message::recipient(message),
        message::created_at(message),
        message::expires_at(message),
        message::is_read(message),
    )
}

/// Verifica se mensagem expirou
public fun check_expired(message: &Message, clock: &Clock): bool {
    let now = clock::timestamp_ms(clock) / 1000;
    message::is_expired(message, now)
}
