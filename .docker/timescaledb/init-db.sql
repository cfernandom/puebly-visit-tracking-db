\c pueblyVisitTracking;

CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE users (
    uuid UUID NOT NULL,
    PRIMARY KEY (uuid)
);

CREATE TABLE posts (
    id INTEGER NOT NULL,
    -- title VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE user_visits (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    post_id INTEGER NOT NULL,
    PRIMARY KEY (time, user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(uuid),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- CREATE TABLE user_visits_2020_01 PARTITION OF user_visits FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

SELECT create_hypertable('user_visits', 'time', if_not_exists => TRUE);

CREATE TABLE user_conversions (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    post_id INTEGER NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('call', 'whatsapp', 'location')),
    PRIMARY KEY (time, user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(uuid),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- CREATE TABLE user_conversions_2020_01 PARTITION OF user_conversions FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

SELECT create_hypertable('user_conversions', 'time', if_not_exists => TRUE);

-- INDEXES
CREATE INDEX idx_user_visits_time ON user_visits(time);
CREATE INDEX idx_user_visits_post_id ON user_visits(post_id);
CREATE INDEX idx_user_visits_time_post_id ON user_visits(time, post_id);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION notify_user_visits() 
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('user_visits', row_to_json(NEW)::text);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_user_conversions() 
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('user_conversions', row_to_json(NEW)::text);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- TRIGGERS
CREATE TRIGGER
    notify_user_visits_trigger
    AFTER INSERT
    ON user_visits
    FOR EACH ROW
EXECUTE PROCEDURE notify_user_visits();

CREATE TRIGGER
    notify_user_conversions_trigger
    AFTER INSERT
    ON user_conversions
    FOR EACH ROW
EXECUTE PROCEDURE notify_user_conversions();

-- Automatically managed partitioning

-- SELECT add_retention_policy('user_visits', INTERVAL '12 months');
-- SELECT add_retention_policy('user_conversions', INTERVAL '12 months');

-- Compression policies
SELECT add_compression_policy('user_visits', INTERVAL '30 days');