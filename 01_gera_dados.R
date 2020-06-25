
library(tidyverse)
library(readxl)
library(janitor)

options(OutDec = ",")

# ---- lê o arquivo
# as bases não têm o mesmo formato
# vou ter que ler cada uma e arrumar

# origem dos dados de 2018
# https://www.timeshighereducation.com/world-university-rankings/young-university-rankings-2018-golden-age-results-out-now

dados_2018 <- rio::import("the_golden-age.xlsx", sheet = "2018") %>% 
  clean_names() %>% 
  # não tenho interesse no ranking 2017, pois a UnB não se classificou
  select(-golden_age_rank_2017) %>% 
  # padronizar a variável do rank e de citações
  rename(golden_age_rank = golden_age_rank_2018,
         world_university_rank = world_university_rank_2018,
         citation_impact = citations) %>% 
  # cria variável para identificar o ano
  mutate(year = 2018)

# origem dos dados de 2019
# https://www.timeshighereducation.com/student/best-universities/best-golden-age-universities

dados_2019 <- rio::import("the_golden-age.xlsx", sheet = "2019") %>% 
  clean_names() %>% 
  # não tenho interesse no ranking 2018, já estou pegando na outra planilha
  select(-golden_age_rank_2018) %>% 
  # padronizar a variável do rank
  rename(golden_age_rank = golden_age_rank_2019,
         world_university_rank = world_university_rank_2019) %>% 
  # cria variável para identificar o ano
  mutate(year = 2019)

# origem dos dados 2020
# https://www.timeshighereducation.com/world-university-rankings/young-university-rankings-2020-golden-age-results-out-now

dados_2020 <- rio::import("the_golden-age.xlsx", sheet = "2020") %>% 
  clean_names() %>% 
  # não tenho interesse no ranking 2019, já estou pegando na outra planilha
  select(-golden_age_rank_2019) %>% 
  # padronizar a variável do rank
  rename(golden_age_rank = golden_age_rank_2020,
         industry_income = industry,
         international_outlook = international,
         overall_score = overall) %>% 
  # cria variável para identificar o ano
  mutate(year = 2020)

# junta as duas bases
dados <- bind_rows(dados_2018, dados_2019, dados_2020)
rm(dados_2018, dados_2019, dados_2020)

# arruma as variáveis
dados <- dados %>% 
  mutate_at(vars(teaching:international_outlook), as.double) %>% 
  # recalcula o overall score
  # https://www.timeshighereducation.com/world-university-rankings/young-university-rankings-2019-methodology
  mutate(overall_score = 0.3*teaching + 0.3*research + 0.3*citation_impact + 0.075*international_outlook + 0.025*industry_income)

# verifica as variáveis
glimpse(dados)

dados %>% filter(is.na(.))

# tem alguns NAs, vamos consertar
# parece que a planilha original de 2018 era mesclada(?)
# vou recriar essa variável

dados <- dados %>% 
  group_by(year) %>% 
  arrange(desc(overall_score)) %>% 
  mutate(golden_age_rank = row_number())

map(dados %>% select(teaching:overall_score), summary)

# parece tudo ok. salvar os dados limpos

rio::export(dados, "the_golden-age_limpo.xlsx")

# ---- dados do Brasil

dados_br <- dados %>% 
  filter(country_region == "Brazil")

# cria a variável de rank nacional & federal

dados_br <- dados_br %>% 
  mutate(country_rank = row_number()) %>% 
  left_join(dados_br %>% 
              filter(str_detect(institution, "Federal") | institution == "University of Brasília") %>% 
              mutate(federal_rank = row_number()) %>% 
              select(year, institution, federal_rank)) %>% 
  ungroup()

# vou precisar das siglas

siglas <- dados_br %>% 
  distinct(institution) %>% 
  mutate(sigla = case_when(
    
    institution == "University of Campinas" ~ "Unicamp",
    institution == "State University of Campinas" ~ "Unicamp",
    institution == "Federal University of Santa Catarina" ~ "UFSC",
    institution == "Pontifical Catholic University of Rio Grande do Sul (PUCRS)" ~ "PUCRS",
    institution == "University of Brasília" ~ "UnB",
    institution == "Federal University of Bahia" ~ "UFBA",
    institution == "Federal University of Ceará (UFC)" ~ "UFC",
    institution == "Pontifical Catholic University of Paraná" ~ "PUCPR",
    institution == "Federal University of Pernambuco" ~ "UFPB",
    institution == "Rio de Janeiro State University (UERJ)" ~ "UERJ",
    institution == "Federal University of Rio Grande do Norte (UFRN)" ~ "UFRN",
    institution == "Federal University of Goiás" ~ "UFG",
    institution == "Fluminense Federal University" ~ "UFF",
    institution == "Federal University of Santa Maria" ~ "UFSM",
    institution == "Federal University of Pará" ~ "UFPA",
    institution == "Santa Catarina State University" ~ "UDESC",
    institution == "Federal University of Espírito Santo" ~ "UFES",
    institution == "Federal University of Alagoas" ~ "UFAL",
    institution == "Federal University of Mato Grosso do Sul" ~ "UFMS",
    institution == "Pontifical Catholic University of Minas Gerais" ~ "PUCMG",
    institution == "University of Caxias do Sul" ~ "UCS"
    
  ))

dados_br <- dados_br %>% left_join(siglas)

# salvar os dados BR

rio::export(dados_br, "the_golden-age_limpo_BR.xlsx")
