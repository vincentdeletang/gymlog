-- Add optional equipment tare per exercise
-- weight_kg in set_logs = plates only; bar_weight_kg = bar/dumbbell tare
-- Displayed weight in history/charts = weight_kg + bar_weight_kg
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS bar_weight_kg DECIMAL(5,2) NULL;
