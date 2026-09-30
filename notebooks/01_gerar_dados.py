import pandas as pd
import numpy as np
from faker import Faker

Faker.seed(42)
fake = Faker("pt_BR")
rng = np.random.default_rng(42)
n = 1500

cat_rec = ["Vendas", "Serviços", "Recebimento de clientes"]
cat_desp = ["Fornecedores", "Salários", "Aluguel", "Impostos", "Energia", "Marketing", "Software"]

# ---------- Lançamentos do financeiro (a "verdade" interna) ----------
tipo = rng.choice(["Receita", "Despesa"], n, p=[0.45, 0.55])
lanc = pd.DataFrame({
    "id_lancamento": np.arange(1, n + 1),
    "data": pd.to_datetime("2025-01-01") + pd.to_timedelta(rng.integers(0, 365, n), unit="D"),
    "tipo": tipo,
    "categoria": np.where(tipo == "Receita", rng.choice(cat_rec, n), rng.choice(cat_desp, n)),
    "contraparte": [fake.company() for _ in range(n)],
    "valor": np.round(rng.uniform(150, 20000, n), 2),
})

# ---------- Extrato bancário (derivado dos lançamentos, com problemas) ----------
ext = lanc[rng.random(n) > 0.05].copy()
m = len(ext)

atraso = np.where(rng.random(m) < 0.25, rng.integers(1, 4, m), 0)
ext["data"] = ext["data"] + pd.to_timedelta(atraso, unit="D")

div = rng.random(m) < 0.03
ext.loc[div, "valor"] = (ext.loc[div, "valor"] - np.round(rng.uniform(5, 50, div.sum()), 2)).round(2)

prefixo = ext["tipo"].map({"Receita": "PIX RECEBIDO ", "Despesa": "PAGTO "})
ext["descricao"] = prefixo + ext["contraparte"].str.upper()
ext["tipo"] = ext["tipo"].map({"Receita": "Crédito", "Despesa": "Débito"})
ext = ext[["data", "descricao", "tipo", "valor"]]

duplicados = ext.sample(15, random_state=1)
tarifas = pd.DataFrame({
    "data": pd.date_range("2025-01-01", periods=12, freq="MS"),
    "descricao": "TARIFA MANUTENCAO CONTA",
    "tipo": "Débito",
    "valor": 89.90,
})
ext = pd.concat([ext, duplicados, tarifas]).sort_values("data").reset_index(drop=True)
ext.insert(0, "id_extrato", np.arange(1, len(ext) + 1))

# ---------- Sujar os lançamentos (para treinar limpeza) ----------
lanc.loc[lanc.sample(20, random_state=2).index, "categoria"] = None
sujo = rng.random(n) < 0.10
lanc.loc[sujo, "contraparte"] = lanc.loc[sujo, "contraparte"].str.upper() + " "
lanc = pd.concat([lanc, lanc.sample(15, random_state=3)]).sample(frac=1, random_state=4)

lanc.to_csv("data/lancamentos_raw.csv", index=False)
ext.to_csv("data/extrato_raw.csv", index=False)
print(len(lanc), "lançamentos |", len(ext), "linhas de extrato")