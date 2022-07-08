# NODA_MCU
Sensoriamento Ambiental de Laboratório de Ensaio.  
Foi utilizado um ESP32 com sensor DHT22 para aquisição de Temperatura de Umidade de um Laboratório de Ensaios. 
O ESP32 foi configurado para coletar os valores de Temperatura e Umidade com frequencia de 1 segundo e transmitindo a média a cada minuto. 
Os valores são transmitidos para a plataforma de IoT Thingsboard para monitoramente em tempo real com a possibilidade de alarmes.
Um software foi desenvolvido para coletar os valores de ambiente no range de tempo que o laboratório estava realizando determinado ensaio
para geração de um relatório com o gráfico de temperatura e umidade ambiente e seu valor médio para ser anexado ao relatório.
