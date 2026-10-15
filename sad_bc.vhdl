--------------------------------------------------
--	Author:      Ismael Seidel (entity)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade `sad_bc`, que representa o
--               bloco de controle (BC) do circuito para cálculo da soma das
--               diferenças absolutas (SAD - Sum of Absolute Differences).
--               Este bloco é responsável pela geração dos sinais de controle
--               necessários para coordenar o funcionamento do bloco operativo
--               (BO), como enable de registradores, seletores de multiplexadores,
--               sinais de início e término de processamento, etc.
--               A arquitetura é comportamental e deverá descrever uma máquina
--               de estados finitos (FSM) adequada ao controle do datapath.
--               Os sinais adicionais de controle devem ser definidos conforme
--               a necessidade do projeto. PS: já foram definidos nos slides
--               da aula 6T.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- Bloco de Controle (BC) do circuito SAD.
-- Responsável por gerar os sinais de controle para o bloco operativo (BO),
-- geralmente por meio de uma FSM.
entity sad_bc is
	port(
		clk   : in std_logic;  -- clock (sinal de relógio)
		rst_a : in std_logic;   -- reset assíncrono ativo em nível alto
		enable   : in  std_logic;
        menor    : in  std_logic;
        zM1      : out std_logic;
        ci       : out std_logic;
        cPA      : out std_logic;
        cPB      : out std_logic;
        zM2      : out std_logic;
        cAC      : out std_logic;
        cSA      : out std_logic;
        read_mem : out std_logic;
        done     : out std_logic
        );
		-- defina os demais sinais necessários
		-- não esqueça de colocar o ; no final da linha que declara o rst_a :)
end entity;
-- Não altere o nome da entidade nem da arquitetura!

architecture behavior of sad_bc is
    -- Se necessário, declare sinais internos aqui.
    type state_t is (S0, S1, S2, S3, S4, S5);
    signal current_state, next_state : state_t;
begin

    -- Descreva a FSM responsável por coordenar o circuito SAD.
    
    -- Dica: separar em 3 processos:
    -- 1) carga e reset do registrador de estado;
    
    process(clk, rst_a)
    begin
        if rst_a = '1' then
            current_state <= S0;
            
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process; 
    
    -- 2) LPE;
    
    process (current_state, enable, menor)
    begin
        case current_state is 
            when S0 =>
                if enable = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
        
            when S1 => 
                next_state <= S2;
                
            when S2 =>
                if menor = '1' then
                    next_state <= S3;
                else 
                    next_state <= S5;
                end if; 
                
            when S3 =>
                next_state <= S4;
            
            when S4 => 
                next_state <= S2;
            
            when S5 =>
                next_state <= S0;
            
            when others => 
                next_state <= S0;
            
        end case;
    end process;
    
    -- 3) LS;
    
    process (current_state)
        begin 
            zM1      <= '0';
            ci       <= '0';
            cPA      <= '0';
            cPB      <= '0';
            zM2      <= '0';
            cAC      <= '0';
            cSA      <= '0';
            read_mem <= '0';
            done     <= '0';
            
            case current_state is
                when S0 =>
                    done <= '1';
                    read_mem <= '0';
                
                when S1 =>
                    zM1 <= '1';
                    ci  <= '1';
                    zM2 <= '1';
                    cAC <= '1';
                    done <= '0';
                   
                
                when S2 => 
                    null;
                
                when S3 =>
                    read_mem <= '1';
                    cPA     <= '1';
                    cPB     <= '1';
                    
                when S4 =>
                    read_mem <= '0';
                    ci       <= '1';
                    cAC      <= '1';
                    zM1      <= '0';
                    zM2      <= '0';

                when S5 =>
                    cSA <= '1';
                
            end case;
        
    end process;
        
        
        
        
        
        
        
        
        
        
    
    

    -- 3) LS.
end architecture;
