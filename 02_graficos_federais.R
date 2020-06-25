
library(tidyverse)
library(readxl)
library(janitor)
library(ggbump)
library(showtext)
library(ggtext)
library(patchwork)

options(OutDec = ",")

# importa os dados já tratados
dados_br <- rio::import("the_golden-age_limpo_BR.xlsx")

# planejo fazer dois gráficos
# um da trajetória da posição
# e outro da evolução das notas da UnB

# ---- gráfico de evolução dos indicadores da UnB - FEDERAIS

# mapeamento das cores para cada universidade
# pantone classic blue #0F4C81
# pantone silver-plated #BCB29E
# pantone opal gray #A49E9E
cores <- c("Unicamp"    = "#A49E9E",
           "UFSC"       = "#A49E9E",
           "PUCRS"      = "#A49E9E",
           "UFBA"       = "#A49E9E",
           "UFC"        = "#A49E9E",
           "PUCPR"      = "#A49E9E",
           "UFPB"       = "#A49E9E",
           "UERJ"       = "#A49E9E",
           "UFRN"       = "#A49E9E",
           "UFG"        = "#A49E9E",
           "UFF"        = "#A49E9E",
           "UFSM"       = "#A49E9E",
           "UFPA"       = "#A49E9E",
           "UFAL"       = "#A49E9E",
           "UFMS"       = "#A49E9E",
           "UFES"       = "#A49E9E",
           "PUCMG"      = "#A49E9E",
           "UCS"        = "#A49E9E",
           "UDESC"      = "#A49E9E",
           "UnB"        = "#0F4C81")

# dados para os gráficos dos indicadores
dados_graf_ind <- dados_br %>% 
  select(year, sigla, teaching:international_outlook) %>% 
  pivot_longer(cols = teaching:international_outlook,
               names_to = "indicador",
               values_to = "valor") %>% 
  mutate(indicador = case_when(
    
    indicador == "citation_impact" ~ "CITAÇÕES\nPeso: 30%",
    indicador == "industry_income" ~ "INDÚSTRIA\nPeso: 2,5%",
    indicador == "international_outlook" ~ "INTERNACIONALIZAÇÃO\nPeso: 7,5%",
    indicador == "research" ~ "PESQUISA\nPeso: 30%",
    indicador == "teaching" ~ "ENSINO\nPeso: 30%"
    
  ),
  # o ano completo atrapalha a visualização, cortei
  year = as.double(str_remove(year, "^\\d{2}")))

font_add("charter", "C:/Users/GUILHERME/AppData/Local/Microsoft/Windows/Fonts/Charter Regular.otf")
font_add("charter-bold", "C:/Users/GUILHERME/AppData/Local/Microsoft/Windows/Fonts/Charter Bold.otf")
font_add("fira", "C:/Users/GUILHERME/AppData/Local/Microsoft/Windows/Fonts/FiraSans-Regular.ttf")
showtext_auto()

theme_set(theme_light(base_family = "charter"))
theme_update(legend.position = "none",
             axis.line.y = element_blank(),
             axis.line.x = element_blank(),
             panel.grid.minor = element_blank())

graf_ind_fed <- dados_graf_ind %>% 
  filter(sigla %in% c("UFSC", "UnB", "UFC", "UFBA", "UFPB", "UFRN", "UFG", "UFF", "UFES", "UFSM", "UFPA", "UFAL", "UFMS")) %>% 
  ggplot(aes(x = year, y = valor, color = sigla)) +
  geom_line() +
  geom_point(size = 0.75, shape = 21) +
  facet_grid(cols = vars(indicador)) +   # switch = "both" faria a legenda do facet ir para baixo
  scale_x_continuous(breaks = c(18, 19, 20)) +
  scale_color_manual(values = cores, guide = F) +
  labs(title = "Evolução dos indicadores das Universidades Federais no Ranking THE <span style='color:#FFD700'>Golden Age</span>",
       subtitle = "A <span style='color:#0F4C81'>Universidade de Brasília</span> é a melhor em internacionalização e melhorou em quatro dos cinco indicadores,<br>em especial nas citações, que correspondem a 30% da nota",
       x = "Ano de divulgação do ranking",
       y = "Nota no indicador") +
  theme(plot.subtitle = element_markdown(family = "charter", lineheight = 1.2),
        plot.title = element_markdown(family = "charter-bold"),
        axis.title.x = element_text(hjust = 1, size = 8),
        axis.title.y = element_text(hjust = 1, size = 8),
        panel.grid.major.x = element_blank(),
        strip.text.x = element_text(size = 7))

graf_ind_fed
ggsave("the-ga-ind-federais.pdf", width = 8, height = 3, device = cairo_pdf)
pdftools::pdf_convert("the-ga-ind-federais.pdf", format = "png", dpi = 350)

# ---- gráfico de evolução das posições - FEDERAL

theme_set(theme_classic(base_family = "charter"))
theme_update(legend.position = "none",
             axis.line.y = element_blank(),
             axis.line.x = element_blank())

graf_pos_fed <- dados_br %>% 
  filter(!is.na(federal_rank)) %>% 
  ggplot(aes(x = year, y = federal_rank, color = sigla)) +
  geom_point(size = 4) +
  geom_bump(size = 2, smooth = 8) +
  geom_text(data = dados_br %>% filter(year == min(year)), family = "fira",
            aes(x = year - .1, label = sigla), size = 5, hjust = 1) +
  geom_text(data = dados_br %>% filter(year == max(year)), family = "fira",
            aes(x = year + .1, label = sigla), size = 5, hjust = 0) +
  geom_text(data = dados_br %>% filter(year == max(year)), family = "fira",
            aes(x = year + 0.4, label = glue::glue("{federal_rank}ª"), size = 5, hjust = 0)) +
  scale_y_reverse(breaks = c(seq(1, 18))) +
  scale_x_continuous(limits = c(2017.7, 2020.5),
                     breaks = c(2018, 2019, 2020)) +
  scale_color_manual(values = cores, guide = F) +
  labs(title = "Evolução da posição das Universidades Federais no Ranking THE <span style='color:#FFD700'>Golden Age</span>",
       subtitle = "Dentre as IFES Federais que têm mais de 50 e menos de 80 anos desde sua criação,<br>a <span style='color:#0F4C81'>Universidade de Brasília</span> mantém a 2ª posição nos últimos três anos",
       x = "Ano de divulgação do ranking",
       y = "", 
       caption = "Fonte: timeshighereducation.com/student/best-universities/best-golden-age-universities\nElaboração: DAI/DPO/UnB") +
  theme(axis.title.x = element_text(hjust = 0.74),
        axis.text.y = element_text(size = 10),
        plot.title = element_markdown(family = "charter-bold"),
        plot.subtitle = element_markdown(lineheight = 1.2),
        plot.caption = element_text(margin = margin(10,0,0,0)))

graf_pos_fed
ggsave("the-ga-federais.pdf", width = 8, height = 5, device = cairo_pdf)
pdftools::pdf_convert("the-ga-federais.pdf", format = "png", dpi = 350)

# ---- gráfico conjunto FEDERAL

graf_ind_fed / graf_pos_fed + plot_layout(heights = c(1, 3))
ggsave("the-ga-federais_conjunto.pdf", width = 8, height = 8, device = cairo_pdf)
pdftools::pdf_convert("the-ga-federais_conjunto.pdf", format = "png", dpi = 350)

showtext_auto(FALSE)
