--------------------------------------------------
--	Author:      Ismael Seidel (entity)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade sad (que é o top-level). Tal
--               Entidade calcula a Soma das Diferenças Absolutas (SAD) entre
--               duas matrizes (blocos) de amostras, chamadas de bloco original
--               e bloco candidato. Ambos os blocos estão armazenados em memórias 
--               externas: o bloco original está em uma memória chamada de Mem_A
--               e o bloco candidato está em uma memória chamada de Mem_B. As
--               memórias são lidas de maneira assíncrona, através de um sinal
--               de endereço (address) e um sinal que habilita a leitura (read_mem).
--               O valor lido de Mem_A fica disponível na entrada sample_ori, 
--               enquanto que o valor lido de Mem_B fica fisponível na entrada
--               sample_can. O número de bits de cada amostra é parametrizado
--               através do generic bits_per_sample, que tem valor padrão 8. Os
--               valores de cada amostra são números inteiros sem sinal. Além 
--               disso, o número total de amostras por bloco também é parametrizável
--               através do generic samples_per_block. Porém, neste exercício você
--               pode assumir que esse valor não será modificado e será sempre 64.
--               Com 64 amostras em um bloco, podemos assumir que nossa arquitetura
--               será capaz de calcular a SAD entre dois blocos com tamanho 8x8 (cada).
--               Outro parâmetro da entidade é parallel_samples, que define o número
--               de amostras que serão processadas em paralelo. Neste exercício
--               podemos assumir também que esse valor não será modificado, e o 
--               valor padrão será adotado (ou seja, apenas 1 amostra de cada 
--               bloco será lida da memória por vez). Ainda que não sejam obrigatórios,
--               os generics samples_per_block e parallel_samples devem ser mantidos
--               na descrição da entidade. 
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sad_pack.all;

entity sad is
	generic(
		-- obrigatório ---
		-- defina as operações considerando o número de bits por amostra
		bits_per_sample   : positive := 8; -- número de bits por amostra
		-----------------------------------------------------------------------
		-- desejado (i.e., não obrigatório) ---
		-- se você desejar, pode usar os valores abaixo para descrever uma
		-- entidade que funcione tanto para a SAD v1 quanto para a SAD v3.
		samples_per_block : positive := 64; -- número de amostras por bloco
		parallel_samples  : positive := 1 -- número de amostras de cada bloco lidas em paralelo
		-----------------------------------------------------------------------
	);
	port(
		-- Não modifiquem os nomes das portas e nem mesmo a largura de bits.
		-- Procurem entender as funções address_length e sad_length que são usadas
		-- para a definição do número de bits de endereço (address) e do resultado
		-- final da sad (sad_value).
		-- Note que não podemos usar o nome sad para a saída do valor da SAD, pois
		-- este é o nome de nossa entidade.
		clk        : in  std_logic;     -- ck
		rst_a      : in  std_logic;     -- reset
		enable     : in  std_logic;     -- iniciar
		sample_ori : in  std_logic_vector(bits_per_sample * parallel_samples - 1 downto 0); -- Mem_A[end]
		sample_can : in  std_logic_vector(bits_per_sample * parallel_samples - 1 downto 0); -- Mem_B[end]
		read_mem   : out std_logic;     -- read
		address    : out std_logic_vector(address_length(
			samples_per_block => samples_per_block,
			parallel_samples  => parallel_samples
		) - 1 downto 0);                -- end
		sad_value  : out std_logic_vector(sad_length(
			bits_per_sample   => bits_per_sample,
			samples_per_block => samples_per_block
		) - 1 downto 0);                -- SAD
		done       : out std_logic      -- pronto
	);
end entity sad;

-- Não alterar o nome da arquitetura!
architecture structure of sad is
signal zM1_s, ci_s, cPA_s, cPB_s, zM2_s, cAC_s, cSA_s : std_logic;
	signal menor_s : std_logic;

	-- Configuração repassada ao BO
	constant DATAPATH_CFG : datapath_configuration_t := (
		bits_per_sample   => bits_per_sample,
		samples_per_block => samples_per_block,
		parallel_samples  => parallel_samples
	);
begin

	-- Implementar aqui.
	-- Há duas opções para a implementação. 
	-- 1) Uma delas é usando um wrapper (para agrupar os sinais de controle em records).
	-- 2) Implementar diretamente a instanciação do BO (sad_bo) e BC (sad_bc).
    -- Instanciação do Bloco de Controle (BC)
	BC_INST: entity work.sad_bc(behavior)
		port map (
			clk      => clk,
			rst_a    => rst_a,
			enable   => enable,
			menor    => menor_s,
			zM1      => zM1_s,
			ci       => ci_s,
			cPA      => cPA_s,
			cPB      => cPB_s,
			zM2      => zM2_s,
			cAC      => cAC_s,
			cSA      => cSA_s,
			read_mem => read_mem,
			done     => done
		);

	-- Instanciação do Bloco Operativo (BO)
	BO_INST: entity work.sad_bo(structure)
		generic map (
			CFG => DATAPATH_CFG
		)
		port map (
			clk     => clk,
			zM1     => zM1_s,
			ci      => ci_s,
			cPA     => cPA_s,
			cPB     => cPB_s,
			zM2     => zM2_s,
			cAC     => cAC_s,
			cSA     => cSA_s,
			menor   => menor_s,
			a       => sample_ori,
			b       => sample_can,
			address => address,
			SAD     => sad_value
		);

end architecture structure; 