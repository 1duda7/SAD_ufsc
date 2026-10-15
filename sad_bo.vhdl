--------------------------------------------------
--	Author:      Ismael Seidel (entidade)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade `sad_bo`, que representa o
--               bloco operativo (BO) do circuito para cálculo da soma das
--               diferenças absolutas (SAD - Sum of Absolute Differences).
--               Este bloco implementa o *datapath* principal do circuito e
--               realiza operações como subtração, valor absoluto e acumulação
--               dos valores calculados. Além disso, também será feito aqui o
--               calculo de endereçamento e do sinal de controle do laço de
--               execução (menor), que deve ser enviado ao bloco de controle (i.e.,
--               menor será um sinal de status gerado no BO).
--               A parametrização é feita por meio do tipo
--               `datapath_configuration_t` definido no pacote `sad_pack`.
--               Os parâmetros incluem:
--               - `bits_per_sample`: número de bits por amostra; (uso obrigatório)
--               - `samples_per_block`: número total de amostras por bloco; (uso 
--                  opcional, útil para definição do número de bits da sad e 
--                  endereço, conforme feito no top-level, i.e., no arquivo sad.vhdl)
--               - `parallel_samples`: número de amostras processadas em paralelo.
--                  (uso opcional)
--               A arquitetura estrutural instanciará os componentes necessários
--               à implementação completa do bloco operativo.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sad_pack.all;

-- Bloco Operativo (BO) do circuito SAD.
-- Responsável pelo processamento aritmético dos dados de entrada, incluindo
-- subtração, cálculo de valor absoluto e soma acumulada.
-- Totalmente parametrizável por meio do tipo `datapath_configuration_t`.
entity sad_bo is
	generic(
		CFG : datapath_configuration_t := (
			bits_per_sample   => 8,  -- número de bits por amostra
			samples_per_block => 64, -- número total de amostras por bloco
			parallel_samples  => 1   -- paralelismo no processamento
		)
	);
	port(
-- Sinais de Comando (BC -> BO)
        clk     : in std_logic;
        zM1     : in  std_logic;
        ci      : in  std_logic;
        cPA     : in  std_logic;
        cPB     : in  std_logic;
        zM2     : in  std_logic;
        cAC     : in  std_logic;
        cSA     : in  std_logic;
        -- Sinal de Status (BO -> BC)
        menor   : out std_logic;
        -- Dados de Entrada/Saída
        a       : in  std_logic_vector(CFG.bits_per_sample - 1 downto 0);
        b       : in  std_logic_vector(CFG.bits_per_sample - 1 downto 0);
        address : out std_logic_vector(address_length(CFG.samples_per_block, CFG.parallel_samples) - 1 downto 0);
        SAD     : out std_logic_vector(sad_length(CFG.bits_per_sample, CFG.samples_per_block) - 1 downto 0)
    );
end entity;
-- Não altere o nome da entidade! Como você quem irá instanciar, neste caso podes
-- mudar o nome da arquitetura, embora isso não seja necessário. 
-- A arquitetura será estrutural, composta por instâncias de componentes auxiliares.

architecture structure OF sad_bo is
    -- Se precisar, podes adicionar declarações aqui (remova este comentário).
    constant N      : positive := CFG.bits_per_sample;
    constant ADDR_N : positive := address_length(CFG.samples_per_block, CFG.parallel_samples);
    constant SAD_N  : positive := sad_length(CFG.bits_per_sample, CFG.samples_per_block);

    -- Sinais de Endereço
    signal i1   : std_logic_vector(ADDR_N downto 0);
    signal si   : unsigned(ADDR_N downto 0);
    signal sum1 : unsigned(ADDR_N downto 0);

    -- Sinais de Cálculo
    signal sPA  : unsigned(N - 1 downto 0);
    signal sPB  : unsigned(N - 1 downto 0);
    signal dif  : signed(N downto 0);
    signal sab  : unsigned(N - 1 downto 0);
    signal sum2 : unsigned(SAD_N downto 0);
    signal iAC  : std_logic_vector(SAD_N - 1 downto 0);
    signal sAC  : unsigned(SAD_N - 1 downto 0);
    signal sSA  : unsigned(SAD_N - 1 downto 0);
    
begin
    -- Address:
    
    sum1 <= si + 1;
    
    M1: entity work.mux_2to1(behavior)  
    generic map(N => addr_n +1)
    port map(sel => zM1, in_0 => std_logic_vector(sum1) , in_1=> (OTHERS=> '0') , y => i1);
    
    Ri: entity work.unsigned_register(behavior)  
    generic map(N => addr_n + 1)
    port map(clk => clk, enable => ci, d => unsigned(i1) , q=> si );
    
    menor <= not std_logic(si(addr_n));
    address <= std_logic_vector(si((addr_n -1) downto 0));
    

    
    
    -- calc
    
    PA: entity work.unsigned_register(behavior)  
    generic map(N => N)
    port map(clk => clk, enable => cPA , d => unsigned(a) , q=> sPA );
    
    PB: entity work.unsigned_register(behavior)  
    generic map(N => N)
    port map(clk => clk, enable => cPB , d => unsigned(b) , q=> sPB );
    
    SM: entity work.signed_subtractor(arch)
    generic map(N => N+1)
    port map (input_a => signed('0' & sPA) , input_b => signed('0' & sPB) , difference => dif );
    
    AB: entity work.absolute_difference(structure)
    generic map(N => N)
    port map (input_a => sPA , input_b => sPB , abs_diff => sab ); 
    
    S2: entity work.unsigned_adder(arch)
    generic map(N => sad_n)
    port map (input_a => sAC, input_b => resize(sab, sad_n) , sum =>  sum2 ); 
    
    M2: entity work.mux_2to1(behavior)  
    generic map(N => sad_n)
    port map(sel => zM2, in_0 => std_logic_vector(sum2((sad_n - 1) downto 0)) , in_1=> (OTHERS=> '0') , y => iAC);
    
    CA: entity work.unsigned_register(behavior)  
    generic map(N => sad_n)
    port map(clk => clk, enable => cAC , d => unsigned(iAC) , q=> sAC );
    
    SR: entity work.unsigned_register(behavior)  
    generic map(N => sad_n)
    port map(clk => clk, enable => cSA , d => sAC , q=> sSA );
    
    
    SAD <= std_logic_vector(sSA);
    
    -- A arquitetura deve instanciar módulos para formar o datapath do SAD.
    -- Isso inclui, por exemplo:
    --   - subtratores
    --   - módulos de valor absoluto
    --   - acumuladores
    --   - registradores
    
    -- DICA: Melhor ainda do que instanciar diretamente os componentes listados acima,
    -- minha recomendação é a divisão do bloco operativo em dois submódulos, um que
    -- ficará responsável por calcular os endereços, e o outro que ficará responsável
    -- por calcular o valor da SAD.
end architecture structure;