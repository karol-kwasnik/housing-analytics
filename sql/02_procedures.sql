CREATE OR ALTER PROCEDURE ref.sp_log_ingestion
    @batch_id    VARCHAR(50),
    @status      VARCHAR(20),
    @variable_id INT           = NULL,
    @row_count   INT           = NULL,
    @started_at  DATETIME2     = NULL,
    @message     NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ref.ingestion_log
        (batch_id, variable_id, status, row_count, started_at, finished_at, message)
    VALUES
        (@batch_id, @variable_id, @status, @row_count,
         ISNULL(@started_at, SYSUTCDATETIME()), SYSUTCDATETIME(), @message);

    IF @status = 'OK' AND @variable_id IS NOT NULL
        UPDATE ref.ingestion_config
           SET last_loaded_at = SYSUTCDATETIME()
         WHERE variable_id = @variable_id;
END
GO

CREATE OR ALTER PROCEDURE ref.sp_batch_summary
    @batch_id VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) AS error_count,
        SUM(CASE WHEN status = 'OK'    THEN 1 ELSE 0 END) AS ok_count,
        SUM(ISNULL(row_count, 0))                         AS total_rows
    FROM ref.ingestion_log
    WHERE batch_id = @batch_id;
END
GO
