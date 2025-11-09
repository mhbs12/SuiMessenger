/// Módulo de auto-destruição de mensagens
module sui_messenger::burn;

use sui_messenger::events;
use sui_messenger::message::{Self, Message};
use sui_messenger::verification;
use sui::clock::{Self, Clock};




// ==================== ERRORS ====================

const ENotAuthorized: u64 = 10;
const EAlreadyBurned: u64 = 11;
const ENotExpired: u64 = 12;
const EInvalidBurnProof: u64 = 13;

// ==================== BURN MANUAL ====================

/// Destrói mensagem manualmente (por sender ou recipient)
entry fun burn_message(mut message: Message, clock: &Clock, ctx: &TxContext) {
    let burner = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    let sender = message::sender(&message);
    let recipient = message::recipient(&message);
    assert!(burner == sender || burner == recipient, ENotAuthorized);
    assert!(!message::is_burned(&message), EAlreadyBurned);

    let message_id = object::id(&message);

    // Emite evento
    events::emit_message_burned(
        message_id,
        burner,
        now,
        events::burn_reason_manual(),
    );

    // Destrói
    message::destroy(message);
}

/// Destrói mensagem com proof criptográfico
entry fun burn_message_with_proof(
    message: Message,
    burn_proof: vector<u8>,
    clock: &Clock,
    ctx: &TxContext,
) {
    let burner = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Validações
    assert!(!message::is_burned(&message), EAlreadyBurned);

    // Valida burn proof
    let proof_valid = verification::verify_burn_proof(
        &burn_proof,
        object::uid_to_bytes(message::id(&message)),
        burner,
    );
    assert!(proof_valid, EInvalidBurnProof);

    let message_id = object::id(&message);

    // Emite evento
    events::emit_message_burned(
        message_id,
        burner,
        now,
        events::burn_reason_manual(),
    );

    // Destrói
    message::destroy(message);
}

// ==================== AUTO-BURN ====================

/// Auto-burn de mensagens expiradas (qualquer um pode chamar)
entry fun auto_burn_expired(message: Message, clock: &Clock, ctx: &TxContext) {
    let now = clock::timestamp_ms(clock) / 1000;
    let caller = tx_context::sender(ctx);

    // Só pode queimar se expirou
    assert!(message::is_expired(&message, now), ENotExpired);

    let message_id = object::id(&message);

    // Emite evento
    events::emit_message_burned(
        message_id,
        caller,
        now,
        events::burn_reason_expired(),
    );

    // Destrói
    message::destroy(message);
}
/// Batch burn de múltiplas mensagens expiradas
entry fun batch_auto_burn(mut messages: vector<Message>, clock: &Clock, ctx: &TxContext) {
    let now = clock::timestamp_ms(clock) / 1000;
    let caller = tx_context::sender(ctx);

    let len = vector::length(&messages);
    let mut i = 0;

    while (i < len) {
        let message = vector::pop_back(&mut messages);

        if (message::is_expired(&message, now)) {
            let message_id = object::id(&message);

            events::emit_message_burned(
                message_id,
                caller,
                now,
                events::burn_reason_auto(),
            );

            message::destroy(message);
        } else {
            // Se não expirou, devolve para owner
            transfer::public_transfer(
                message,
                message::recipient(&message),
            );
        };

        i = i + 1;
    };

    vector::destroy_empty(messages);
}
