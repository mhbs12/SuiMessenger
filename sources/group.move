/// Módulo de grupos privados
module sui_messenger::group;

use sui_messenger::events;
use sui_messenger::verification;
use std::string::{Self, String};
use sui::clock::{Self, Clock};



// ==================== ESTRUTURAS ====================

/// Grupo privado com membership verificável
public struct PrivateGroup has key, store {
    id: UID,
    name: String,
    admin: address,
    member_commitment: vector<u8>, // Hash ZK dos membros
    member_count: u64,
    message_count: u64,
    created_at: u64,
}

// ==================== ERRORS ====================

const ENotAdmin: u64 = 20;
const EInvalidMembershipProof: u64 = 21;

// ==================== CRIAR GRUPO ====================

/// Cria grupo privado
entry fun create_private_group(
    name: vector<u8>,
    member_commitment: vector<u8>,
    member_count: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let admin = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    let group = PrivateGroup {
        id: object::new(ctx),
        name: string::utf8(name),
        admin,
        member_commitment,
        member_count,
        message_count: 0,
        created_at: now,
    };

    let group_id = object::uid_to_inner(&group.id);

    // Emite evento
    events::emit_group_created(
        group_id,
        admin,
        member_count,
        now,
    );

    transfer::transfer(group, admin);
}

// ==================== ENVIAR MENSAGEM NO GRUPO ====================

/// Envia mensagem para grupo (precisa provar membership)
entry fun send_group_message(
    group: &mut PrivateGroup,
    membership_proof: vector<u8>,
    walrus_blob_id: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Valida membership proof
    let is_member = verification::verify_membership_proof(
        &membership_proof,
        &group.member_commitment,
        sender,
    );
    assert!(is_member, EInvalidMembershipProof);

    // Incrementa contador
    group.message_count = group.message_count + 1;

    // Emite evento
    events::emit_group_message_sent(
        object::uid_to_inner(&group.id),
        sender,
        now,
    );

    // Na versão completa: criar objeto Message e distribuir
}

// ==================== ADMIN ====================

/// Atualiza commitment dos membros (só admin)
entry fun update_member_commitment(
    group: &mut PrivateGroup,
    new_commitment: vector<u8>,
    new_member_count: u64,
    ctx: &TxContext,
) {
    assert!(group.admin == tx_context::sender(ctx), ENotAdmin);

    group.member_commitment = new_commitment;
    group.member_count = new_member_count;
}

// ==================== GETTERS ====================

public fun name(group: &PrivateGroup): String {
    group.name
}

public fun admin(group: &PrivateGroup): address {
    group.admin
}

public fun member_count(group: &PrivateGroup): u64 {
    group.member_count
}

public fun message_count(group: &PrivateGroup): u64 {
    group.message_count
}

public fun get_info(group: &PrivateGroup): (String, address, u64, u64) {
    (group.name, group.admin, group.member_count, group.message_count)
}
