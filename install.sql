CREATE TABLE IF NOT EXISTS kuban_comp (
    code VARCHAR(10) PRIMARY KEY,
    item VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    playerId INT NULL
);
