module sui_messenger::group;

use std::string::{Self, String};
use sui::clock::{Self, Clock};
use sui_messenger::events;

public struct PrivateGroup has key, store {
    id: UID,
    name: String,
    admin: address,
    members: vector<address>,
    member_count: u64,
    message_count: u64,
    created_at: u64,
}

const ENotAdmin: u64 = 20;
const ENotMember: u64 = 21;

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

    events::emit_group_created(
        group_id,
        admin,
        member_count,
        now,
    );

    transfer::share_object(group);
}

entry fun send_group_message(
    group: &mut PrivateGroup,
    _walrus_blob_id: vector<u8>,
    clock: &Clock,
    ctx: &TxContext,
) {
    let sender = tx_context::sender(ctx);
    let now = clock::timestamp_ms(clock) / 1000;

    assert!(vector::contains(&group.members, &sender), ENotMember);

    group.message_count = group.message_count + 1;

    events::emit_group_message_sent(
        object::uid_to_inner(&group.id),
        sender,
        now,
    );
}

entry fun set_members(group: &mut PrivateGroup, new_members: vector<address>, ctx: &TxContext) {
    assert!(group.admin == tx_context::sender(ctx), ENotAdmin);

    group.member_count = vector::length(&new_members);
    group.members = new_members;
}

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
