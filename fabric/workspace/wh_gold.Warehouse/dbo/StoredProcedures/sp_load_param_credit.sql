CREATE PROCEDURE dbo.sp_load_param_credit
AS
BEGIN
    TRUNCATE TABLE dbo.param_credit;

    INSERT INTO dbo.param_credit (parameter_name, parameter_value, description)
    SELECT parameter_name, parameter_value, description
    FROM lh_bronze.dbo.credit_parameter;
END