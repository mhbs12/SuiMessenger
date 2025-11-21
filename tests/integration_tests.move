#[test_only]
module sui_messenger::integration_tests;

use sui::clock;
use sui::test_scenario;
use sui_messenger::inbox::{Self, Inbox};
use sui_messenger::message::Message;
use sui_messenger::messenger;

#[test]
fun test_flow_with_inbox() {
    let alice = @0xA;
    let bob = @0xB;

    let mut scenario = test_scenario::begin(alice);
    let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

    // 1. Bob cria Inbox
    test_scenario::next_tx(&mut scenario, bob);
    {
        inbox::create_inbox(test_scenario::ctx(&mut scenario));
    };

    // 2. Alice envia mensagem para Bob
    test_scenario::next_tx(&mut scenario, alice);
    {
        let mut bob_inbox = test_scenario::take_shared<Inbox>(&scenario);

        messenger::send_message(
            bob,
            &mut bob_inbox,
            b"blob_id",
            b"hash",
            b"metadata",
            option::none(),
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Verifica contadores
        assert!(inbox::message_count(&bob_inbox) == 1, 0);
        assert!(inbox::unread_count(&bob_inbox) == 1, 1);

        test_scenario::return_shared(bob_inbox);
    };

    // 3. Bob lê a mensagem
    test_scenario::next_tx(&mut scenario, bob);
    {
        let mut bob_inbox = test_scenario::take_shared<Inbox>(&scenario);
        let mut message = test_scenario::take_from_sender<Message>(&scenario);

        messenger::mark_as_read(
            &mut message,
            &mut bob_inbox,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Verifica contadores
        assert!(inbox::unread_count(&bob_inbox) == 0, 2);

        test_scenario::return_shared(bob_inbox);
        test_scenario::return_to_sender(&scenario, message);
    };

    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
}
