\c pueblyVisitTracking;

CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE users (
    uuid UUID NOT NULL,
    PRIMARY KEY (uuid)
);

CREATE TABLE posts (
    id INTEGER NOT NULL,
    title VARCHAR(255),
    PRIMARY KEY (id)
);

CREATE TABLE post_user_visits (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    post_id INTEGER NOT NULL,
    PRIMARY KEY (time, user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(uuid),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- CREATE TABLE post_user_visits_2020_01 PARTITION OF post_user_visits FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

SELECT create_hypertable('post_user_visits', by_range('time', INTERVAL '1 day'), if_not_exists => TRUE);

CREATE TABLE post_user_interactions (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    post_id INTEGER NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('call', 'whatsapp', 'location')),
    PRIMARY KEY (time, user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(uuid),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- CREATE TABLE post_user_interactions_2020_01 PARTITION OF post_user_interactions FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

SELECT create_hypertable('post_user_interactions', by_range('time', INTERVAL '1 day'), if_not_exists => TRUE);


-- INDEXES
CREATE INDEX idx_post_user_visits_time ON post_user_visits(time);
CREATE INDEX idx_post_user_visits_post_id ON post_user_visits(post_id);
CREATE INDEX idx_post_user_visits_time_post_id ON post_user_visits(time, post_id);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION notify_post_user_visits() 
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('post_user_visits_channel', row_to_json(NEW)::text);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_post_user_interactions() 
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('post_user_interactions_channel', row_to_json(NEW)::text);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- TRIGGERS
CREATE TRIGGER
    notify_post_user_visits_trigger
    AFTER INSERT
    ON post_user_visits
    FOR EACH ROW
EXECUTE PROCEDURE notify_post_user_visits();

CREATE TRIGGER
    notify_post_user_interactions_trigger
    AFTER INSERT
    ON post_user_interactions
    FOR EACH ROW
EXECUTE PROCEDURE notify_post_user_interactions();

-- Automatically managed partitioning

-- SELECT add_retention_policy('post_user_visits', INTERVAL '12 months');
-- SELECT add_retention_policy('post_user_interactions', INTERVAL '12 months');

-- Compression policies
-- SELECT add_compression_policy('post_user_visits', INTERVAL '30 days');