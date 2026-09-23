-- Fitness Platform / Product V3.6 hardening
-- Bind AI runs/actions/messages to one conversation owner and one conversation chain.

ALTER TABLE ai_conversation
    ADD UNIQUE KEY uk_ai_conversation_user_id (user_id, id);

ALTER TABLE ai_message
    ADD UNIQUE KEY uk_ai_message_conversation_id (conversation_id, id);

ALTER TABLE ai_agent_run
    ADD UNIQUE KEY uk_ai_agent_run_user_conversation_id (user_id, conversation_id, id),
    ADD KEY idx_ai_agent_run_conversation_user_message (conversation_id, user_message_id),
    ADD KEY idx_ai_agent_run_conversation_assistant_message (conversation_id, assistant_message_id),
    DROP FOREIGN KEY fk_ai_agent_run_conversation,
    DROP FOREIGN KEY fk_ai_agent_run_user_message,
    DROP FOREIGN KEY fk_ai_agent_run_assistant_message,
    ADD CONSTRAINT fk_ai_agent_run_conversation_owner_v36
        FOREIGN KEY (user_id, conversation_id)
        REFERENCES ai_conversation(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_agent_run_user_message_v36
        FOREIGN KEY (conversation_id, user_message_id)
        REFERENCES ai_message(conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_agent_run_assistant_message_v36
        FOREIGN KEY (conversation_id, assistant_message_id)
        REFERENCES ai_message(conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE ai_action_audit
    ADD KEY idx_ai_action_user_conversation_run (user_id, conversation_id, agent_run_id),
    DROP FOREIGN KEY fk_ai_action_conversation,
    DROP FOREIGN KEY fk_ai_action_agent_run,
    ADD CONSTRAINT fk_ai_action_conversation_owner_v36
        FOREIGN KEY (user_id, conversation_id)
        REFERENCES ai_conversation(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_action_agent_run_chain_v36
        FOREIGN KEY (user_id, conversation_id, agent_run_id)
        REFERENCES ai_agent_run(user_id, conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;
