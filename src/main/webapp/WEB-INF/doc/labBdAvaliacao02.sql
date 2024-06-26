﻿﻿-- use master
-- drop database labBdAvaliacao02

create database labBdAvaliacao02
go
use labBdAvaliacao02
go
create table Curso (
codCurso		int				not null check(codCurso >= 0 and codCurso <= 100),
nome			varchar(100)	not null,
cargaHoraria	int				not null,
sigla			varchar(3)		not null,
notaEnade		int				not null
Primary Key(codCurso)
)
go
create table Aluno (
cpf					char(11)		not null unique,
codCurso			int				not null,
ra					char(9)			not null,
nome				varchar(150)	not null,
nomeSocial			varchar(150)	null,
dataNascimento		date			not null,
email				varchar(100)	not null,
dataConclusao2Grau	date			not null ,
emailCorporativo	varchar(100)	not null,
instituicao2Grau	varchar(100)	not null,
pontuacaoVestibular	int				not null,
posicaoVestibular	int				not null,
anoIngresso			int				not null,
semestreIngresso	int				not null,
semestreLimite		int				not null,
anoLimite			int				not null,
turno				varchar(10)		not null
Primary Key(cpf)
Foreign Key(codCurso) references Curso(codCurso),
constraint verificaDataConclusao check (dataConclusao2Grau > dataNascimento)
)
go
create table Telefone (
numero		char(11)	not null,
cpf			char(11)	not null
Primary key(numero, cpf)
Foreign key(cpf) references Aluno(cpf)
)
go
-- Drop function calcularHoraFinal
-- FUNCTION CalcularHoraFinal 
create function calcularHoraFinal (@horaInicio time, @horasSemanais time)
returns time
as
begin
    declare @horaFinal time;
    declare @horas int;
    declare @minutos int;

    set @horas = datepart(hour, @horasSemanais);

    set @minutos = datepart(minute, @horasSemanais);

    set @horaFinal = dateadd(hour, @horas, @horaInicio);
    set @horaFinal = dateadd(minute, @minutos, @horaFinal);

    return @horaFinal
end

go
create table Professor (
	codProfessor			int,
	nome					varchar(100)
	primary key (codProfessor)
)
go
create table Disciplina (
codDisciplina	int				not null identity(1001, 1),
codProfessor	int				not null,
codCurso		int				not null,
nome			varchar(100)	not null,
horasSemanais	time			not null,
horaInicio		time			not null,
horaFinal as dbo.calcularHoraFinal(HoraInicio, HorasSemanais),
diaSemana		varchar(15)		not null,
semestre		int				not null
Primary key(codDisciplina)
Foreign key(codCurso) references Curso(codCurso),
Foreign key(codProfessor) references Professor(codProfessor)
)
go
-- drop table Matricula
create table Matricula (
anoSemestre		int				not null,
cpf				char(11)		not null,
codDisciplina	int				not null,
statusMatricula	varchar(10)		not null default ('pendente'),
nota			decimal(3,1)	null,
dataMatricula	date			not null,
Primary key(anoSemestre, cpf, codDisciplina),
Foreign key(cpf) references Aluno(cpf),
Foreign key(codDisciplina) references Disciplina(codDisciplina)
)

go
create table Conteudo (
codConteudo		int				not null,
codDisciplina	int				not null,
nome			varchar(100)	not null
Primary key(codConteudo)
Foreign key(codDisciplina) references Disciplina(codDisciplina)
)
go
--drop table ListaChamada
create table ListaChamada (
dataChamada				date			not null,
anoSemestre				int				not null,
cpf						char(11)		not null,
codDisciplina			int				not null,
presenca				int				not null,
ausencia				int				not null,
aula1					char(1)			not null,
aula2					char(1)			not null,
aula3					char(1)			null,
aula4					char(1)			null
primary key(dataChamada, anoSemestre, cpf, codDisciplina),
foreign key (anoSemestre, cpf, codDisciplina) references Matricula (anoSemestre, cpf, codDisciplina)
)
go
create table Dispensa (
cpf						char(11)				not null references Aluno (cpf),
codDisciplina			int						not null references Disciplina (codDisciplina),
dataDispensa			date					not null,
statusDispensa			varchar(10)				default ('em analise'),				
instituicao				varchar(100)			not null
primary key(cpf, codDisciplina)
)

go
--PROCEDURE QUE VALIDA SE O CPF EXISTE OU É INVALIDO
--drop procedure sp_consultaCpf
create procedure sp_consultaCpf(@cpf char(11), @valido bit output)
as
--VARIAVEIS
	declare @i int, @valor int, @status int, @x int
--VALORES DAS VARIAVEIS
	set @i = 0
	set @status = 0
	set @x = 2

--verifica se cpf tem 11 digitos
if(LEN(@cpf) = 11)begin
	--VERIFICACAO DE DIGITOS REPETIDOS
	while(@i < 10) begin
		if(SUBSTRING(@cpf, 1,1) = SUBSTRING(@cpf, @x, 1)) begin
			set @status = @status + 1
		end 
	set @i = @i + 1
	set @x = @x + 1
	end
	--Descobrindo o digito 10
	If(@status < 10)begin
		declare @ValorMultiplicadoPor2 int
		set @valor = 10
		set @i = 0
		set @x = 1
		set @ValorMultiplicadoPor2 = 0
		
		while (@i < 9) begin
			set @ValorMultiplicadoPor2 = CAST(SUBSTRING(@cpf, @x, 1) as int) * @valor + @ValorMultiplicadoPor2  
			set @x = @x + 1
			set @i = @i + 1
			set @valor = @valor - 1
		end
		
		declare @valorDividido int, @primeiroDigito int 

		set @valorDividido = @ValorMultiplicadoPor2 % 11

		if(@valorDividido < 2)begin
			set @primeiroDigito = 0
		end else begin
			set @primeiroDigito = 11 - @valorDividido
		end

		-- verifica se o digito descoberto � igual o inserido

		if(CAST(SUBSTRING(@cpf, 10,1)as int) = @primeiroDigito) begin
			--descobrindo segundo digito
			set @valor = 11
			set @i = 0
			set @x = 1
			set @ValorMultiplicadoPor2 = 0

			while (@i < 10) begin
			set @ValorMultiplicadoPor2 =  CAST(SUBSTRING(@cpf, @x, 1) as int) * @valor + @ValorMultiplicadoPor2
			set @x = @x + 1
			set @i = @i + 1
			set @valor = @valor - 1
			end
			
			declare @segundoDigito int
			set @valorDividido = @ValorMultiplicadoPor2 % 11

			if(@valorDividido < 2)begin
				set @segundoDigito = 0
			end else begin
				set @segundoDigito = 11 - @valorDividido
			end

			if(CAST(SUBSTRING(@cpf, 11,1)as int) = @segundoDigito) begin
					set @valido  = 1
			end else begin
					set @valido  = 0
					raiserror('CPF inexistente', 16, 1)
			end

		end else begin
			raiserror('CPF inexistente', 16, 1)
		end

	end else begin
		raiserror('CPF invalido, todos os digitos sao iguais', 16, 1)
	end

end else begin
	raiserror('CPF invalido, numero de caracteres incorreto', 16, 1)
end


go
--PROCEDURE QUE VALIDA SE ALUNO TEM 16 ANOS OU MAIS
-- drop procedure sp_validaIdade
create procedure sp_validaIdade(@dataNascimento date, @validaIdade bit output)
as
	if(datediff(year, @dataNascimento, getdate()) >= 16)begin
		set @validaIdade = 1
	end
	else
	begin
		set @validaIdade = 0
		raiserror('A idade é menor que 16 anos', 16, 1)
	end

go
--PROCEDURE QUE CALCULA 5 ANOS DO ANO DE INGRESSSO	
-- drop function fn_anoLimite
create function fn_anoLimite(@anoIngresso int)
returns int
as
begin
		declare @anoLimite int
		set @anolimite = @anoIngresso + 5
		return @anoLimite
end

go
-- Funcao para criacao de RA
-- drop function fn_criaRa
create function fn_criaRa (@anoIngresso int, @semestreIngresso int, @random1 int, @random2 int, @random3 int, @random4 int)
returns @tabela table (
	statusRa	 bit,
	ra			char(9)
)
begin

    declare @ra char(9),
			@raExistente char(9)

	set @raExistente = null

	set @ra = cast(@anoIngresso as char(4)) + cast(@semestreIngresso as char(1)) + cast(@random1 as char(1)) + cast(@random2 as char(1)) + cast(@random3 as char(1)) + cast(@random4 as char(1))	

	set @raExistente = (select ra from Aluno where ra = @ra)

	if(@raExistente is null)
	begin
			insert into @tabela (statusRa, ra) values (1, @ra)
	end
	else
	begin
			insert into @tabela (statusRa, ra) values (0, @ra)
	end
	
    return 
end

go
--FUNCTION QUE CRIA O EMAIL CORPORATIVO
-- Drop function fn_criaEmailCorporativo
create function fn_criaEmailCorporativo(@nome varchar(150), @ra char(9))
returns varchar (100)
as
begin

	set @nome = LOWER(@nome)
	set @nome = REPLACE(@nome, ' ', '.')

	set @nome = @nome + RIGHT(@ra, 4) + '@agis.com'
	return @nome
end

go
--PROCEDURE QUE VALIDA SE CPF é UNICO NO BANCO DE DADOS DO SISTEMA
-- drop procedure sp_validaCpfDuplicado
create procedure sp_validaCpfDuplicado(@cpf char(11), @validaCpfDuplicado bit output)
as
	declare @cpfExistente char(11)

	set @cpfExistente = null

	set @cpfExistente = (select cpf from aluno where cpf = @cpf)

	if(@cpfExistente is null)
	begin
		set @validaCpfDuplicado = 1
	end
	else
	begin
		set @validaCpfDuplicado = 0
	end

go
-- PROCEDURE PARA VERIFICAÇÃO DE RA
-- drop procedure sp_validaRa
create procedure sp_validaRa(@ra char(9), @saida bit output)
as
	declare @raExistente char(9)

	set @raExistente = null

	set @raExistente = (select ra from aluno where ra = @ra)

	if(@raExistente is null)
	begin
		set @saida = 0
	end
	else
	begin
		set @saida = 1
	end

go
-- PROCEDURE QUE VALIDA SE CURSO É EXISTENTE
-- drop procedure sp_validaCurso
create procedure sp_validaCurso(@codCurso int, @validaCurso bit output)
as
	set @codCurso = (select codCurso from Curso where codCurso = @codCurso)

	if(@codCurso is not null)
	begin
		set @validaCurso = 1
	end
	else 
	begin
		set @validaCurso = 0
		raiserror('O codigo do curso é invalido', 16, 1)
	end

go
--PROCEDURE QUE VALIDA SE TELEFONE EXISTE
-- drop procedure sp_validaTelefone
create procedure sp_validaTelefone(@telefone char(11), @validaTelefone bit output)
as
	set @telefone = (select numero from Telefone where numero = @telefone)

	if(@telefone is not null)
	begin
		set @validaTelefone = 1
	end
	else 
	begin
		set @validaTelefone = 0
	end

go
--PROCEDURE PARA INSERIR E ATUALIZAR ALUNO
-- drop procedure sp_iuAluno
create procedure sp_iuAluno(@op char(1), @cpf char(11), @codCurso int, @nome varchar(150), @nomeSocial varchar(150), @dataNascimento date, @email varchar(100), @dataConclusao2Grau date,
							@instituicao2Grau varchar(100), @pontuacaoVestibular int, @posicaoVestibular int, @anoIngresso int, @semestreIngresso int, @semestreLimite int, 
							@saida varchar(100) output)
as
		declare @validaCpf bit
		exec sp_consultaCpf @cpf, @validaCpf output 
		if(@validaCpf = 1)
		begin
				
				declare @validaIdade bit
				exec sp_validaIdade @dataNascimento, @validaIdade output
				if(@validaIdade = 1)
				begin
							declare @validaCurso bit
							exec sp_validaCurso @codCurso, @validaCurso output
							if(@validaCurso = 1)
							begin		
										if(upper(@op) = 'I')						
										begin

												declare @validarDuplicidadeCpf bit
												exec sp_validaCpfDuplicado @cpf, @validarDuplicidadeCpf output
												if(@validarDuplicidadeCpf = 1)
												begin
															declare	@ra char(9),
																	@emailCorporativo varchar(100),
																	@random1 int,
																	@random2 int, 
																	@random3 int, 
																	@random4 int,
																	@status bit

															set @status = 0

															while(@status = 0)begin
									
																set @random1 = CAST(RAND() * 10 as int)
																set @random2 = CAST(RAND() * 10 as int)
																set @random3 = CAST(RAND() * 10 as int)
																set @random4 = CAST(RAND() * 10 as int)

																set @status = (select statusRa from fn_criaRa(2024, 1, @random1, @random2, @random3, @random4))
								
															end

															set @ra = (select ra from fn_criaRa(2024, 1, @random1, @random2, @random3, @random4))
								

															set @emailCorporativo = (select dbo.fn_criaEmailCorporativo(@nome, @ra) as emailCorporativo)

															declare @anolimite int
															set @anoLimite = (select dbo.fn_anoLimite(@anoIngresso) as anoLimite)
								
															insert into Aluno values (@cpf, @codCurso, @ra, @nome, @nomeSocial, @dataNascimento, @email, @dataConclusao2Grau, @emailCorporativo, @instituicao2Grau,
																				 @pontuacaoVestibular, @posicaoVestibular, @anoIngresso, @semestreIngresso, @semestreLimite, @anolimite, 'Vespertino')

											
															set @saida = 'Aluno inserido com sucesso'
															return
												end
												else
												begin
															raiserror('CPF já cadastrado', 16, 1)
															return
												end
										end
										else
											if(upper(@op) = 'U')
											begin
									
													update Aluno
													set nome = @nome, dataNascimento = @dataNascimento, nomeSocial = @nomeSocial, email = @email, codCurso = @codCurso, dataConclusao2Grau = @dataConclusao2Grau, 
													instituicao2Grau = @instituicao2Grau, pontuacaoVestibular = @pontuacaoVestibular, posicaoVestibular = @posicaoVestibular
													where cpf = @cpf

										
													set @saida = 'Aluno atualizado com sucesso'	
													return
											end
											else
											begin
													raiserror('Operação invalida', 16, 1)
													return
											end
							end	
				end	
		end

go
-- FUNCTION PARA OBTER ANOSEMESTRE
-- drop function fn_obterAnoSemestre
create function fn_obterAnoSemestre ()
returns varchar(5)
begin
		declare @anoSemestre varchar(5),
				@ano int,
				@mes int;

		
		set @ano = year(getdate())
		set @mes = month(getdate())


		if @mes >= 1 and @mes <= 6
			set @anoSemestre = cast(@ano as varchar(4)) + '1'
		else
			set @anoSemestre = cast(@ano as varchar(4)) + '2'

		return @anoSemestre
				
end

go
-- trigger que insere os auluno em todas materias do primeiro semestre logo apos ele ser inserido
-- disable trigger t_matriculaAluno on Aluno
-- drop trigger t_matriculaAluno
create trigger t_matriculaAluno on Aluno
after insert
as 
begin
		declare @i int,
				@codCurso int,
				@cpf char(11),
				@codDisciplina int,
				@anoSemestre int

		set @codDisciplina = 0 
				
		set @codCurso = (select codCurso from inserted)

		set @i = (select count(codDisciplina) from Disciplina where semestre = 1 and codCurso = @codCurso)

		set @cpf = (select cpf from inserted)

		set @anoSemestre = dbo.fn_obterAnoSemestre()


		create table #disciplinas(
			cod		int 
		)

		insert into #disciplinas (cod) 
			   select codDisciplina from Disciplina where semestre = 1 and codCurso = @codCurso

		while(@i > 0)
		begin
			
			set @codDisciplina =  (select top 1 cod from #disciplinas)

			insert into Matricula (anoSemestre, cpf, codDisciplina, dataMatricula) values
			(@anoSemestre, @cpf, @codDisciplina, getdate())

			delete top (1) from #disciplinas

			set @i = @i - 1

		end

end

go
-- Procedure que cadastra e atualiza telefone
-- drop procedure sp_iudTelefone
create procedure sp_iudTelefone(@op char(1), @cpf char(11), @telefoneAntigo char(11) null, @telefoneNovo char(11), 
								@saida  varchar(150) output)
as
		declare @validaTelefone bit 

		declare @validarExistenciaCpf bit
		exec sp_validaCpfDuplicado @cpf, @validarExistenciaCpf output

		if(@validarExistenciaCpf = 0) 
		begin
				if(len(@telefoneNovo) = 11)
				begin
						if(upper(@op) = 'U')
						begin
								if(len(@telefoneAntigo) = 11)
								begin
										
										exec sp_validaTelefone @telefoneAntigo, @validaTelefone output
										if(@validaTelefone = 1)
										begin

													update Telefone set numero = @telefoneNovo where cpf = @cpf and numero = @telefoneAntigo

													set @saida = 'Telefone atualizado com sucesso'

													return
										end
										else
										begin
													raiserror('O telefone não existe no banco de dados', 16, 1)
										end
								end
								else
								begin
													raiserror('Tamanho de telefone incorreto', 16, 1)
								end
						end
						
						if(upper(@op) = 'D')
						begin
										exec sp_validaTelefone @telefoneNovo, @validaTelefone output
										if(@validaTelefone = 1)
										begin
														delete Telefone where cpf = @cpf and numero = @telefoneNovo

														set @saida = 'Telefone excluido com sucesso'
														
														return
										end
										else
										begin
														raiserror('O telefone não existe no banco de dados', 16, 1)
										end
						end
								
						if(upper(@op) = 'I')
						begin
									exec sp_validaTelefone @telefoneNovo, @validaTelefone output
									if(@validaTelefone = 0)
									begin
												insert into Telefone (cpf, numero) values (@cpf, @telefoneNovo)

												set @saida = 'Telefone cadastrado com sucesso'

												return
									end
									else
									begin
												raiserror('O telefone ja existe no banco de dados', 16, 1)
									end
						end
						else
						begin
									raiserror('Operação invalida', 16, 1)
						end
				end 
				else
				begin
					raiserror('Tamanho de telefone incorreto', 16, 1)
				end
		end
		else
		begin
				raiserror('O CPF não existe na base de dados do sistema', 16, 1)
		end

go
--FUNCTION FN_POPULARMATRICULA
--drop function fn_popularMatricula
create function fn_popularMatricula(@ra char(9))
returns @tabela table (
	diaSemana	varchar(15),
	codDisciplina	int,
	disciplina	varchar(100),
	horasSemanais	time,
	horaInicio		time,
	statusMatricula	varchar(20)
)
begin
	
		declare @codCurso int

		set @codCurso = (select codCurso from Aluno where ra = @ra)

		insert into @tabela (diaSemana, codDisciplina, disciplina, horasSemanais, horaInicio, statusMatricula)
					select d.diaSemana, d.codDisciplina, d.nome, d.horasSemanais, convert(varchar(5), d.horaInicio, 108) as horaInicio, 'não matriculado' as statusMatricula
					from Disciplina d left outer join Matricula m on d.codDisciplina = m.codDisciplina
					where m.cpf is null and d.codCurso = @codCurso
	
		insert into @tabela (diaSemana, codDisciplina, disciplina, horasSemanais, horaInicio, statusMatricula)
					select d.diaSemana, d.codDisciplina, d.nome, d.horasSemanais, convert(varchar(5), d.horaInicio, 108) as horaInicio , m.statusMatricula
					from Disciplina d, Matricula m
					left join Matricula m1 on m1.cpf = m.cpf
							  and m1.codDisciplina = m.codDisciplina
							  and m1.anoSemestre > m.anoSemestre
							  and m1.statusMatricula = 'Aprovado'
					where d.codCurso = @codCurso and
						  m.statusMatricula = 'Reprovado'
						  and m1.anoSemestre is null and 
						  d.codDisciplina = m.codDisciplina

		return
		
end
	
go
-- PROCEDURE sp_cadastrarMatricula
-- drop procedure sp_cadastrarMatricula
create procedure sp_cadastrarMatricula(@ra char(9), @codDisciplinaRequerida int, @saida varchar(150) output)
as
		declare @codCurso int,
				@diaSemana varchar(15),
				@horaInicioDisciplinaRequerida time,
				@horaInicioDisciplinaMatriculada time,
				@horaFinalDisciplinaMatriculada time,
				@horaFinalDisciplinaRequerida time,
				@qtdMatricula int,
				@cpf char(11),
				@anoSemestre varchar(5),
				@valida bit

		set @valida = 0

		set @cpf = (select cpf from Aluno where ra = @ra)

		set @codCurso = (select codCurso from Aluno where ra = @ra)

		set @diaSemana = (select diaSemana from Disciplina where codDisciplina = @codDisciplinaRequerida)

		set @horaInicioDisciplinaRequerida = (select horaInicio from Disciplina where codDisciplina = @codDisciplinaRequerida)

		set @horaFinalDisciplinaRequerida = (select horaFinal from Disciplina where codDisciplina = @codDisciplinaRequerida)
									
		set @qtdMatricula = (select count(*) from matricula m, Disciplina d 
							 where lower(m.statusMatricula) = lower('Pendente') 
							 and m.codDisciplina = d.codDisciplina and
							 d.codCurso = @codCurso and d.diaSemana = @diaSemana)

		if (@qtdMatricula = 0)
		begin

			set @anoSemestre = dbo.fn_obterAnoSemestre()

			insert into Matricula (anoSemestre, cpf, codDisciplina, dataMatricula) values
			(@anoSemestre, @cpf, @codDisciplinaRequerida, getdate())

			set @saida = 'Matricula realizada com sucesso'
		end

		create table #matriculastemp(
			horaInicioDisciplinaMatriculada time,
			horaFinalDisciplinaMatriculada time,
		)
		
		insert into #matriculastemp (horaInicioDisciplinaMatriculada, horaFinalDisciplinaMatriculada)
									SELECT d.horaInicio, d.horaFinal
									FROM matricula m, Disciplina d 
									WHERE LOWER(m.statusMatricula) = LOWER('Pendente') 
									AND d.codCurso = @codCurso 
									AND d.diaSemana = @diaSemana and
									m.codDisciplina = d.codDisciplina

		while(@qtdMatricula > 0)
		begin
			

				set @horaInicioDisciplinaMatriculada = (select top 1 horaInicioDisciplinaMatriculada from #matriculastemp)

				set @horaFinalDisciplinaMatriculada = (select top 1 horaFinalDisciplinaMatriculada from #matriculastemp)

				delete top (1) from #matriculastemp

				if((@horaInicioDisciplinaRequerida not between @horaInicioDisciplinaMatriculada and @horaFinalDisciplinaMatriculada)
				and 
				(@horaFinalDisciplinaRequerida not between @horaInicioDisciplinaMatriculada and @horaFinalDisciplinaMatriculada))
				begin

							set @valida  = 1

				end
				else
				begin
							set @valida = 0
							drop table #matriculastemp
							raiserror('Já existe um materia cadastrada nesse intervalo de horario', 16, 1)
							return
				end		

				set @qtdMatricula = @qtdMatricula - 1
				
		end

		if(@valida = 1)
		begin
				set @anoSemestre = dbo.fn_obterAnoSemestre()

				insert into Matricula (anoSemestre, cpf, codDisciplina, dataMatricula) values
						(@anoSemestre, @cpf, @codDisciplinaRequerida, GETDATE())

				set @saida = 'Matricula realizada com sucesso'
		end

go
-- function que faz historico do aluno
-- drop function fn_historico
create function fn_historico (@ra char(9))
returns @historico table(
	ra							char(9),
	nome						varchar(150),
	nomeCurso					varchar(100),
	dataPrimeiraMatricula		date,
	pontuacaoVestibular			int,
	posicaoVestibular			int
)
as
begin
	
	declare @nome						varchar(150),
			@nomeCurso					varchar(100),
			@dataPrimeiraMatricula		date,
			@pontuacaoVestibular		int,
			@posicaoVestibular			int,
			@cpf						char(11)

	set @cpf = (select cpf from Aluno where ra = @ra)
	
	set @nome = (select nome from Aluno where ra = @ra)

	set @nomeCurso = (select c.nome from aluno a, Curso c where a.codCurso = c.codCurso and a.ra = @ra)

	set @dataPrimeiraMatricula = (select top 1 m.dataMatricula from aluno a, Matricula m where a.cpf = m.cpf and a.cpf = @cpf order by m.dataMatricula desc)

	set @pontuacaoVestibular = (select pontuacaoVestibular from Aluno where ra = @ra)

	set @posicaoVestibular = (select posicaoVestibular from Aluno where ra = @ra)

	insert into @historico (ra, nome, nomeCurso, dataPrimeiraMatricula, pontuacaoVestibular, posicaoVestibular)
	values (@ra, @nome, @nomeCurso, @dataPrimeiraMatricula, @pontuacaoVestibular, @posicaoVestibular)

	return

end

go
-- function que faz lista de matriculas aprovadas 
-- drop function fn_matriculaAprovada
create function fn_matriculaAprovada(@ra char(9))
returns @matriculas table (
		codDisciplina		int,
		nomeDisciplina		varchar(100),
		nomeProfessor		varchar(100),
		notaFinal			varchar(10),
		qtdFaltas			int
)
as
begin
		insert into @matriculas (codDisciplina, nomeDisciplina, nomeProfessor, notaFinal, qtdFaltas)
					select d.codDisciplina, d.nome, p.nome,
						   case 
						   when (m.statusMatricula like 'Dispensado') then 'D'
						   else cast(m.nota as varchar(10))
						   end as notaFinal, 
						   (select sum(l.ausencia) 
							from ListaChamada l 
							where l.anoSemestre = m.anoSemestre 
							and l.cpf = m.cpf 
							and l.codDisciplina = m.codDisciplina) as qtdFaltas
					from Disciplina d, professor p, Matricula m 
					where d.codProfessor = p.codProfessor and
						  d.codDisciplina = m.codDisciplina and
						  m.cpf =(select cpf from Aluno where ra = @ra )
						  and (m.statusMatricula like 'Aprovado' or 
						  m.statusMatricula like 'Dispensado')
	return
end

go
-- procedure que insere dispensa
-- drop procedure sp_iDispensa
create procedure sp_iDispensa (@cpf char(11), @codDisciplina int, @instituicao varchar(100) ,@saida varchar(100) output)
as 
		declare @validaCpf bit
		exec sp_consultaCpf @cpf, @validaCpf output 
		if(@validaCpf = 1)
		begin
				declare @validarDuplicidadeCpf bit
				exec sp_validaCpfDuplicado @cpf, @validarDuplicidadeCpf output
				if(@validarDuplicidadeCpf = 0)
				begin
						insert into Dispensa (cpf, codDisciplina, dataDispensa, instituicao) values 
						(@cpf, @codDisciplina, getdate(), @instituicao)

						set @saida = 'Solicitacao de dispensa enviada para secretaria'
				end
				else
				begin
						raiserror('Cpf nao esta cadastrado', 16, 1)
				end
		end

go
--procedure que atualiza resposta da secretaria e atualiza matricula
-- drop procedure sp_atualizaDispensa
create procedure sp_atualizaDispensa (@ra char(9), @codDisciplina varchar(100), @statusDispensa varchar(20), @saida varchar(100) output)
as 
		declare @cpf char(11),
				@anoSemestre varchar(5),
				@matriuculaExiste int,
				@ano int,
				@mes int

		set @matriuculaExiste = null

		set @cpf = (select cpf from Aluno where ra = @ra)

		update Dispensa 
		set statusDispensa = @statusDispensa 
		where cpf = @cpf and codDisciplina = @codDisciplina

		set @saida = 'Solicitacao indeferida'

		if(@statusDispensa like 'Deferido')
		begin

			set @ano = year(getdate())
			set @mes = month(getdate())

			if (@mes >= 1 and @mes <= 6)
				set @anoSemestre = cast(@ano as varchar(4)) + '1'
			else
				set @anoSemestre = cast(@ano as varchar(4)) + '2'

				set @matriuculaExiste = (select count(*) as matricula
				from Matricula
				where anoSemestre = @anoSemestre
					  and cpf = @cpf
					  and codDisciplina = @codDisciplina)

				if(@matriuculaExiste = 1)
				begin
				
					update Matricula set 
					statusMatricula = 'Dispensado' 
					where anoSemestre = @anoSemestre
						  and cpf = @cpf
						  and codDisciplina = @codDisciplina
					  
				end
				else
				begin

					insert Matricula (anoSemestre, cpf, codDisciplina, statusMatricula, dataMatricula)
					values (@anoSemestre, @cpf, @codDisciplina, 'Dispensado', getdate())

				end

				set @saida = 'Dispensa Deferida e Matricula Dispensada'

		end

go
-- procedure que traz disciplinas que o professor esta matriculado
-- drop procedure sp_validaProfessor
create procedure sp_validaProfessor (@codProfessor int, @saida bit output)
as
	
	declare @professorExiste int,
			@professorPossuDisciplina int
	
	set @professorExiste = 0
	
	set @professorPossuDisciplina = 0

	set @professorExiste = (select Count(codProfessor) from Professor where codProfessor = @codProfessor)
	
	if(@professorExiste = 1)
	begin
			set @professorPossuDisciplina = (select count(codDisciplina) from Disciplina where codProfessor = @codProfessor)

			if(@professorPossuDisciplina > 0)
			begin
				set @saida = 1
			end
			else
			begin
				set @saida = 0
				raiserror('Professor nao leciona nenhuma disciplina', 16, 1)
			end
	end
	else
	begin
		set @saida = 0
		raiserror('O codigo de professor nao existe', 16, 1)
	end

go
-- procedure que cadastra chamada
-- drop procedure sp_cadastraChamada
create procedure sp_cadastraChamada (@dataChamada date, @anoSemestre int, @cpf char(11), @codDisciplina int, 
										@presencas int, @ausencias int, @aula1 char(1), @aula2 char(1), @aula3 char(1),
										@aula4 char(1))
as
	insert into ListaChamada values
	(@dataChamada, @anoSemestre, @cpf, @codDisciplina, @presencas, @ausencias, @aula1, @aula2, @aula3, @aula4)

go 
-- procedure que traz data das chamadas da disicplina selecionada 
--drop function fn_obterChamadasUnicas
create function fn_obterChamadasUnicas(@codDisciplina int)
returns @tabela table (
    dataChamada       date,
    nome              varchar(100),
    anoSemestre       int,
    cpf               char(11),
    codDisciplina     int
)
as 
begin
    declare @anoSemestre int
    set @anoSemestre = dbo.fn_obterAnoSemestre()

    insert into @tabela (dataChamada, nome, anoSemestre, cpf, codDisciplina)
    select dataChamada, nome, @anoSemestre, cpf, codDisciplina
    from (
        select lc.dataChamada, d.nome, lc.cpf, lc.codDisciplina,
               ROW_NUMBER() over (partition by lc.dataChamada order by lc.dataChamada) as row_num
        from ListaChamada lc
        inner join Disciplina d on lc.codDisciplina = d.codDisciplina
        where lc.anoSemestre = @anoSemestre
          and lc.codDisciplina = @codDisciplina
    ) as subquery
    where row_num = 1

    return
end	

go

-- procedure que atualiza chamada
-- drop procedure sp_atualizaChamada
create procedure sp_atualizaChamada (@presenca int, @ausencia int, @aula1 char(1), @aula2 char(1), 
										@aula3 char(1), @aula4 char(1), @codDisciplina int, @cpf char(11), @dataChamada date)
as
	update ListaChamada
		set presenca = @presenca, ausencia = @ausencia, aula1 = @aula1, aula2 = @aula2, aula3 = @aula3, aula4 = @aula4
	where dataChamada = @dataChamada 
			and anoSemestre = (dbo.fn_obterAnoSemestre()) 
			and codDisciplina = @codDisciplina
			and cpf = @cpf

---TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES------TESTES---					 



--- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT --- --- INSERT ---
-- Tabela Curso
go
-- Inserir múltiplas linhas na tabela Curso
INSERT INTO Curso (codCurso, nome, cargaHoraria, sigla, notaEnade) 
VALUES 
    (1, 'Análise e Desenvolvimento de Sistemas', 3000, 'ADS', 4),
    (2, 'Medicina', 6000, 'MED', 5),
    (3, 'Administração', 3200, 'ADM', 3),
    (4, 'Ciência da Computação', 3500, 'CCO', 4),
    (5, 'Direito', 3800, 'DIR', 4),
    (6, 'Psicologia', 3400, 'PSI', 3),
    (7, 'Engenharia Elétrica', 4200, 'ELE', 4),
    (8, 'Arquitetura e Urbanismo', 4000, 'ARQ', 4),
    (9, 'Economia', 3000, 'ECO', 3),
    (10, 'Letras', 2800, 'LET', 3);

go
INSERT INTO Professor (codProfessor, nome) 
VALUES 
    (1, 'Prof. João Silva'),
    (2, 'Prof. Maria Oliveira'),
    (3, 'Prof. Carlos Santos'),
    (4, 'Prof. Ana Souza'),
    (5, 'Prof. Pedro Almeida');

go
-- Inserir disciplinas para o curso de Engenharia Civil (codCurso = 1)
INSERT INTO Disciplina (codCurso, nome, horasSemanais, horaInicio, diaSemana, semestre, codProfessor)
VALUES 
(1, 'Cálculo I', '3:30', '13:00', 'Segunda-feira', 1, 1),
(1, 'Álgebra Linear', '1:40', '14:50', 'Segunda-feira', 2, 2),
(1, 'Física I', '1:40', '16:40', 'Segunda-feira', 3, 3),
(1, 'Desenho Técnico', '1:40', '13:00', 'Segunda-feira', 4, 4),
(1, 'Introdução à Engenharia', '3:30', '14:50', 'Segunda-feira', 5, 5),

(1, 'Engenharia de Materiais', '3:30', '13:00', 'Terça-feira', 6, 1),
(1, 'Geometria Analítica', '1:40', '14:50', 'Terça-feira', 1, 3),
(1, 'Mecânica Geral', '1:40', '16:40', 'Terça-feira', 2, 4),
(1, 'Topografia', '1:40', '13:00', 'Terça-feira', 3, 3),
(1, 'Fenômenos de Transporte', '3:30', '14:50', 'Terça-feira', 4, 1),

(1, 'Mecânica dos Fluidos', '3:30', '13:00', 'Quarta-feira', 5, 5),
(1, 'Estatística Aplicada', '1:40', '14:50', 'Quarta-feira', 6, 1),
(1, 'Desenho Assistido por Computador', '1:40', '16:40', 'Quarta-feira', 1, 2),
(1, 'Materiais de Construção Civil', '1:40', '13:00', 'Quarta-feira', 2, 3),
(1, 'Probabilidade e Estatística', '3:30', '14:50', 'Quarta-feira', 3, 5),

(1, 'Mecânica dos Solos', '3:30', '13:00', 'Quinta-feira', 4, 4),
(1, 'Hidráulica', '1:40', '14:50', 'Quinta-feira', 5, 1),
(1, 'Construção Civil', '1:40', '16:40', 'Quinta-feira', 6, 3),
(1, 'Gestão de Projetos', '1:40', '13:00', 'Quinta-feira', 1, 3),
(1, 'Sistemas Estruturais', '3:30', '14:50', 'Quinta-feira', 2, 2),

(1, 'Instalações Hidrossanitárias', '3:30', '13:00', 'Sexta-feira', 3, 3),
(1, 'Fundamentos de Engenharia', '1:40', '14:50', 'Sexta-feira', 4, 2),
(1, 'Saneamento Básico', '1:40', '16:40', 'Sexta-feira', 5, 1),
(1, 'Ética Profissional', '1:40', '13:00', 'Sexta-feira', 6, 4),
(1, 'Legislação Ambiental', '3:30', '14:50', 'Sexta-feira', 1, 5);

go
-- Inserir disciplinas para o curso de Medicina (codCurso = 2)
INSERT INTO Disciplina (codCurso, nome, horasSemanais, horaInicio, diaSemana, semestre, codProfessor)
VALUES 
(2, 'Anatomia Humana', '3:30', '13:00', 'Segunda-feira', 1, 1),
(2, 'Fisiologia', '1:40', '14:50', 'Segunda-feira', 2, 2),
(2, 'Bioquímica', '1:40', '16:40', 'Segunda-feira', 3, 3),
(2, 'Histologia', '1:40', '13:00', 'Segunda-feira', 4, 4),
(2, 'Embriologia', '3:30', '14:50', 'Segunda-feira', 5, 5),

(2, 'Farmacologia', '3:30', '13:00', 'Terça-feira', 6, 1),
(2, 'Patologia Geral', '1:40', '14:50', 'Terça-feira', 1, 2),
(2, 'Microbiologia', '1:40', '16:40', 'Terça-feira', 2, 3),
(2, 'Genética', '1:40', '13:00', 'Terça-feira', 3, 4),
(2, 'Imunologia', '3:30', '14:50', 'Terça-feira', 4, 5),

(2, 'Semiologia', '3:30', '13:00', 'Quarta-feira', 5, 1),
(2, 'Epidemiologia', '1:40', '14:50', 'Quarta-feira', 6, 2),
(2, 'Parasitologia', '1:40', '16:40', 'Quarta-feira', 1, 3),
(2, 'Bioética', '1:40', '13:00', 'Quarta-feira', 2, 4),
(2, 'Saúde Pública', '3:30', '14:50', 'Quarta-feira', 3, 5),

(2, 'Neuroanatomia', '3:30', '13:00', 'Quinta-feira', 4, 1),
(2, 'Neurofisiologia', '1:40', '14:50', 'Quinta-feira', 5, 2),
(2, 'Neurologia', '1:40', '16:40', 'Quinta-feira', 6, 3),
(2, 'Psiquiatria', '1:40', '13:00', 'Quinta-feira', 1, 4),
(2, 'Dermatologia', '3:30', '14:50', 'Quinta-feira', 2, 5),

(2, 'Ginecologia', '3:30', '13:00', 'Sexta-feira', 3, 1),
(2, 'Obstetrícia', '1:40', '14:50', 'Sexta-feira', 4, 2),
(2, 'Pediatria', '1:40', '16:40', 'Sexta-feira', 5, 3),
(2, 'Ortopedia', '1:40', '13:00', 'Sexta-feira', 6, 4),
(2, 'Oftalmologia', '3:30', '14:50', 'Sexta-feira', 1, 5);

go
-- Inserir disciplinas para o curso de Administração (codCurso = 3)
INSERT INTO Disciplina (codCurso, nome, horasSemanais, horaInicio, diaSemana, semestre, codProfessor)
VALUES 
(3, 'Gestão Empresarial', '3:30', '13:00', 'Segunda-feira', 1, 1),
(3, 'Contabilidade Financeira', '1:40', '14:50', 'Segunda-feira', 2, 3),
(3, 'Marketing', '1:40', '16:40', 'Segunda-feira', 3, 2),
(3, 'Economia', '1:40', '13:00', 'Segunda-feira', 4, 5),
(3, 'Direito Empresarial', '3:30', '14:50', 'Segunda-feira', 5, 2),

(3, 'Administração de Recursos Humanos', '3:30', '13:00', 'Terça-feira', 6, 1),
(3, 'Gestão de Projetos', '1:40', '14:50', 'Terça-feira', 1, 4),
(3, 'Logística', '1:40', '16:40', 'Terça-feira', 2, 4),
(3, 'Comportamento Organizacional', '1:40', '13:00', 'Terça-feira', 3, 5),
(3, 'Administração Financeira', '3:30', '14:50', 'Terça-feira', 4, 1),

(3, 'Empreendedorismo', '3:30', '13:00', 'Quarta-feira', 5, 5),
(3, 'Negociação', '1:40', '14:50', 'Quarta-feira', 6, 3),
(3, 'Inovação', '1:40', '16:40', 'Quarta-feira', 1, 2),
(3, 'Estratégia Empresarial', '1:40', '13:00', 'Quarta-feira', 2, 3),
(3, 'Consultoria Empresarial', '3:30', '14:50', 'Quarta-feira', 3, 1),

(3, 'Gestão de Qualidade', '3:30', '13:00', 'Quinta-feira', 4, 1),
(3, 'Ética Empresarial', '1:40', '14:50', 'Quinta-feira', 5, 2),
(3, 'Finanças Corporativas', '1:40', '16:40', 'Quinta-feira', 6, 4),
(3, 'Gestão Ambiental', '1:40', '13:00', 'Quinta-feira', 1, 3),
(3, 'Administração Pública', '3:30', '14:50', 'Quinta-feira', 2, 5),

(3, 'Gestão de Tecnologia da Informação', '3:30', '13:00', 'Sexta-feira', 3, 5),
(3, 'Marketing Digital', '1:40', '14:50', 'Sexta-feira', 4, 3),
(3, 'Gestão de Pessoas', '1:40', '16:40', 'Sexta-feira', 5, 1),
(3, 'Comércio Exterior', '1:40', '13:00', 'Sexta-feira', 6, 2),
(3, 'Gestão de Vendas', '3:30', '14:50', 'Sexta-feira', 1, 5);

go
-- Inserindo Aluno 1
DECLARE @saida1 VARCHAR(100)
EXEC sp_iuAluno 'I', '12345678909', 1, 'João Silva', 'João', '2000-01-01', 'joao.silva@example.com', '2018-12-31', 'Escola XYZ', 750, 10, 2024, 1, 1, @saida1 OUTPUT
SELECT @saida1 AS Resultado_Aluno_1
GO

-- Inserindo Aluno 2
DECLARE @saida2 VARCHAR(100)
EXEC sp_iuAluno 'I', '55501820927', 2, 'Maria Souza', null,'2002-05-15', 'maria.souza@example.com', '2019-06-30', 'Escola ABC', 800, 5, 2024, 1, 1, @saida2 OUTPUT
SELECT @saida2 AS Resultado_Aluno_2
GO

-- Inserindo Aluno 3
DECLARE @saida3 VARCHAR(100)
EXEC sp_iuAluno 'I', '85118253047', 3, 'Pedro Santos', null, '1999-09-20', 'pedro.santos@example.com', '2019-12-31', 'Escola QWE', 700, 15, 2024, 1, 1, @saida3 OUTPUT
SELECT @saida3 AS Resultado_Aluno_3
GO

-- Inserindo Aluno 4
DECLARE @saida4 VARCHAR(100)
EXEC sp_iuAluno 'I', '54206134170', 1, 'Carlos Oliveira', null, '2001-03-10', 'carlos.oliveira@example.com', '2020-05-31', 'Escola ASD', 720, 20, 2024, 1, 1, @saida4 OUTPUT
SELECT @saida4 AS Resultado_Aluno_4
GO

-- Inserindo Aluno 5
DECLARE @saida5 VARCHAR(100)
EXEC sp_iuAluno 'I', '03584717531', 2, 'Ana Lima', 'Ana', '1998-07-25', 'ana.lima@example.com', '2019-12-31', 'Escola ZXC', 780, 8, 2024, 1, 1, @saida5 OUTPUT
SELECT @saida5 AS Resultado_Aluno_5

-- Guilherme do Carmo Silveira and Gustavo da Cruz 