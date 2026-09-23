-- Fitness Platform / Product V3.6 hardening
-- Ensure at most one production-active approved version per knowledge document,
-- and freeze approved knowledge text while still allowing vector-index metadata refreshes.

ALTER TABLE knowledge_document_version
    ADD COLUMN active_approved_document_id BIGINT UNSIGNED
        GENERATED ALWAYS AS (
            CASE
                WHEN review_status = 'APPROVED' AND effective_status = 'ACTIVE'
                THEN document_id
                ELSE NULL
            END
        ) STORED,
    ADD UNIQUE KEY uk_knowledge_one_active_approved_version (active_approved_document_id),
    ADD CONSTRAINT ck_knowledge_active_requires_approved_v36 CHECK (
        effective_status <> 'ACTIVE' OR review_status = 'APPROVED'
    );

DELIMITER $$

CREATE TRIGGER trg_knowledge_version_freeze_after_approval_v36
BEFORE UPDATE ON knowledge_document_version
FOR EACH ROW
BEGIN
    IF OLD.review_status = 'APPROVED' THEN
        IF NOT (NEW.document_id <=> OLD.document_id)
           OR NOT (NEW.version_label <=> OLD.version_label)
           OR NOT (NEW.publish_date <=> OLD.publish_date)
           OR NOT (NEW.content_hash <=> OLD.content_hash)
           OR NOT (NEW.source_object_key <=> OLD.source_object_key)
           OR NOT (NEW.reviewed_by_user_id <=> OLD.reviewed_by_user_id)
           OR NOT (NEW.reviewed_at <=> OLD.reviewed_at)
           OR NEW.review_status <> 'APPROVED' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved knowledge document version content/identity is immutable; create a new version instead';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_knowledge_version_block_delete_after_approval_v36
BEFORE DELETE ON knowledge_document_version
FOR EACH ROW
BEGIN
    IF OLD.review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete an approved knowledge version; expire it instead';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_block_insert_into_approved_v36
BEFORE INSERT ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_review_status VARCHAR(32);

    SELECT review_status
      INTO v_review_status
      FROM knowledge_document_version
     WHERE id = NEW.document_version_id;

    IF v_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot add chunks to an approved knowledge version; create a new version instead';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_freeze_text_after_approval_v36
BEFORE UPDATE ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_old_review_status VARCHAR(32);
    DECLARE v_new_review_status VARCHAR(32);

    SELECT review_status
      INTO v_old_review_status
      FROM knowledge_document_version
     WHERE id = OLD.document_version_id;

    SELECT review_status
      INTO v_new_review_status
      FROM knowledge_document_version
     WHERE id = NEW.document_version_id;

    IF v_old_review_status = 'APPROVED' THEN
        IF NOT (NEW.document_version_id <=> OLD.document_version_id)
           OR NOT (NEW.chunk_index <=> OLD.chunk_index)
           OR NOT (NEW.heading <=> OLD.heading)
           OR NOT (NEW.topic <=> OLD.topic)
           OR NOT (NEW.content <=> OLD.content)
           OR NOT (NEW.token_count <=> OLD.token_count)
           OR NOT (NEW.content_hash <=> OLD.content_hash) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved knowledge chunk text is immutable; only index/vector metadata may change';
        END IF;
    END IF;

    IF NEW.document_version_id <> OLD.document_version_id
       AND v_new_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot move a chunk into an approved knowledge version';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_block_delete_after_approval_v36
BEFORE DELETE ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_review_status VARCHAR(32);

    SELECT review_status
      INTO v_review_status
      FROM knowledge_document_version
     WHERE id = OLD.document_version_id;

    IF v_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete chunks from an approved knowledge version; expire the version instead';
    END IF;
END$$

DELIMITER ;
