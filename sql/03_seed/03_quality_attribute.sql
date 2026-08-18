MERGE ref.quality_attribute AS t
USING (VALUES
  (0, N'0', N' ', N'', 0),
  (1, N'wartość', N' ', N'', 1),
  (3, N'wartość', N'k', N'Agregat może być niekompletny', 1),
  (4, N'0', N'x', N'Brak informacji, konieczność zachowania tajemnicy statystycznej lub wypełnienie pozycji jest niemożliwe albo niecelowe', 0),
  (7, N'0', N'a', N'Wartość mniejsza niż przyjęty format prezentacji', 0),
  (9, N'wartość', N's', N'Szacunki wstępne', 1),
  (11, N'wartość', N'M', N'Zmiany metodologiczne', 1),
  (13, N'wartość', N'K', N'Zmiany metodologiczne, agregat może być niekompletny', 1),
  (14, N'0', N'X', N'Zmiany metodologiczne, brak informacji, konieczność zachowania tajemnicy statystycznej lub wypełnienie pozycji jest niemożliwe albo niecelowe', 0),
  (15, N'-', N' ', N'Znak ''-'' oznacza brak informacji z powodu: zmiany poziomu prezentacji, zmian wprowadzonych do wykazu jednostek terytorialnych lub modyfikacji listy cech w danym okresie sprawozdawczym', 0),
  (17, N'0', N'A', N'Zmiany metodologiczne, wartość mniejsza niż przyjęty format prezentacji', 0),
  (20, N'wartość', N'v', N'Dane o niskiej precyzji', 1),
  (21, N'wartość', N'v', N'Dane o niskiej precyzji', 1),
  (50, N'- lub 0', N'n', N'Dana jeszcze niedostępna, będzie dostępna', 0),
  (91, N'0', N'x', N'Brak informacji, konieczność zachowania tajemnicy statystycznej lub wypełnienie pozycji jest niemożliwe albo niecelowe', 0),
  (94, N'0', N'z', N'Wartość znacząca, wartość zerowa wynika z bilansu niezerowych danych wejściowych algorytmu, np. przyrost naturalny, jeśli liczba zgonów jest równa liczbie urodzeń', 1),
  (97, N'wartość', N'p', N'Łącznie dla powiatu i miasta na prawach powiatu', 1),
  (98, N'0', N'Z', N'Zmiany metodologiczne, wartość znacząca, wartość zerowa wynika z bilansu niezerowych danych wejściowych algorytmu, np. przyrost naturalny, jeśli liczba zgonów jest równa liczbie urodzeń', 1)
) AS s (attribute_id, name, symbol, description, is_value)
ON t.attribute_id = s.attribute_id
WHEN MATCHED THEN UPDATE SET
    t.name = s.name, t.symbol = s.symbol, t.description = s.description, t.is_value = s.is_value
WHEN NOT MATCHED THEN INSERT (attribute_id, name, symbol, description, is_value)
    VALUES (s.attribute_id, s.name, s.symbol, s.description, s.is_value);
