/// Módulo de grupos privados
module sui_messenger::group;

use std::string::{Self, String};
use sui::clock::{Self, Clock};
use sui_messenger::events;

// ==================== ESTRUTURAS ====================

/// Grupo privado com membership verificável
public struct PrivateGroup has key, store {
    id: UID,
    name: String,
    admin: address,
    members: vector<address>, // Lista de membros
    member_count: u64,
    message_count: u64,
    created_at: u64,
}

// ==================== ERRORS ====================

const ENotAdmin: u64 = 20;

// ==================== CRIAR GRUPO ====================

/// Cria grupo privado
/// Cria grupo privado
entry fun create_private_group(
    name: vector<u8>,
    members: vector<address>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let admin = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;
    let member_count = vector::length(&members);

    let group = PrivateGroup {
        id: object::new(ctx),
        name: string::utf8(name),
        admin,
        members,
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

/// Envia mensagem para grupo (precisa ser membro)
entry fun send_group_message(
    group: &mut PrivateGroup,
    _walrus_blob_id: vector<u8>,
    clock: &Clock,
    ctx: &TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    // Valida membership
    assert!(vector::contains(&group.members, &sender), ENotAdmin); // Reusing ENotAdmin or should add ENotMember

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

/// Atualiza membros (só admin)
entry fun set_members(group: &mut PrivateGroup, new_members: vector<address>, ctx: &TxContext) {
    assert!(group.admin == tx_context::sender(ctx), ENotAdmin);

    group.member_count = vector::length(&new_members);
    group.members = new_members;
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
