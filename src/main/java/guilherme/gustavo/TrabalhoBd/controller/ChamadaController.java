package guilherme.gustavo.TrabalhoBd.controller;

import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import guilherme.gustavo.TrabalhoBd.model.Disciplina;
import guilherme.gustavo.TrabalhoBd.model.ListaChamada;
import guilherme.gustavo.TrabalhoBd.model.Professor;
import guilherme.gustavo.TrabalhoBd.persistence.ChamadaDao;

@Controller
public class ChamadaController {

	@Autowired
	ChamadaDao cDao;

	@RequestMapping(name = "chamada", value = "/chamada", method = RequestMethod.GET)
	public ModelAndView chamadaGet(@RequestParam Map<String, String> param, ModelMap model) {
		return new ModelAndView("chamada");
	}

	@RequestMapping(name = "chamada", value = "/chamada", method = RequestMethod.POST)
	public ModelAndView chamadaPost(@RequestParam Map<String, String> param, ModelMap model) {

		String cmd = param.get("botao");
		String codigoProfessor = param.get("codigoProfessor");
		String codDisciplina = param.get("codDisciplina");
		String dataChamada = param.get("dataChamda");
		

		String saida = "";
		String erro = "";
		List<Disciplina> disciplinas = new ArrayList<>();
		List<ListaChamada> ListaChamada = new ArrayList<>();
		Professor p = new Professor();
		Disciplina d = new Disciplina();
		
		if (cmd.contains("Buscar Disciplinas")) {
			if (codigoProfessor.trim().isEmpty()) {
				erro = "Por favor, informe o codigo do Professor";
			}
		}
		
		if (cmd.contains("Nova Chamada")){
			if(codigoProfessor.trim().isEmpty() || codDisciplina == null) {
				erro = "Preencha os campos de codigo professor e a disciplina desejada";
			}
		}
		
		if (!erro.isEmpty()) {
			model.addAttribute("erro", erro);
			return new ModelAndView("chamada");
		}
		
		if (cmd.contains("Buscar Disciplinas") || cmd.contains("Nova Chamada") 
				|| cmd.contains("Buscar Chamadas")  ) {
			p.setCodProfessor(Integer.parseInt(codigoProfessor));
		}


		if (cmd.contains("Buscar Chamadas")) {
            try {
                Integer.parseInt(codDisciplina);
            }catch (Exception e) {
            	try {
					if (ValidaProfessor(p) == 1) {
						disciplinas = buscaDisciplina(p);
					}
				} catch (SQLException | ClassNotFoundException e1) {
					erro = e1.getMessage();	
				} finally {
					model.addAttribute("erro", erro);
	                model.addAttribute("codigoProfessor", codigoProfessor);
	    			model.addAttribute("disciplinas", disciplinas);
	                return new ModelAndView("chamada");
				}     
            }
        }

		if (cmd.contains("Buscar Chamadas")) {
				d.setCodigoDisciplina(Integer.parseInt(codDisciplina));
		}

		if (cmd.contains("Nova Chamada")) {
			try {
				if (ValidaProfessor(p) == 1) {
					if (!codDisciplina.contains("Selecione a Disciplina")) {
						model.addAttribute("codigoProfessor", codigoProfessor);
						model.addAttribute("codDisciplina", codDisciplina);
						return new ModelAndView("cadastrarChamada");
					}
				}
			} catch (SQLException | ClassNotFoundException e) {
				erro = e.getMessage();
			}

		}
		
		if (cmd.contains("Alterar")) {
			model.addAttribute("dataChamada", dataChamada);
			model.addAttribute("codDisciplina", codDisciplina);
			return new ModelAndView("editarChamada");
		}

		try {
			if (cmd.contains("Buscar Disciplinas")) {
				if (ValidaProfessor(p) == 1) {
					disciplinas = buscaDisciplina(p);
				}
			}

			if (cmd.contains("Buscar Chamadas")) {
				ListaChamada = buscaChamada(d);
				if(ListaChamada.isEmpty()) {
					erro = "Nao existe chamadas para esta disciplina";
				}
				if (ValidaProfessor(p) == 1) {
					disciplinas = buscaDisciplina(p);
				}
			}
		} catch (SQLException | ClassNotFoundException e) {
			erro = e.getMessage();
		} finally {
			model.addAttribute("saida", saida);
			model.addAttribute("erro", erro);
			model.addAttribute("professor", p);
			model.addAttribute("disciplinas", disciplinas);
			model.addAttribute("ListaChamada", ListaChamada);
//			ListaChamada.get(0).getMatricula().getDisciplina().getCodigoDisciplina();
		}

		return new ModelAndView("chamada");
	}

	private List<ListaChamada> buscaChamada(Disciplina d) throws ClassNotFoundException, SQLException {

		List<ListaChamada> lc = new ArrayList<>();
		lc = cDao.buscaChamada(d);
		return lc;
	}

	private List<Disciplina> buscaDisciplina(Professor p) throws ClassNotFoundException, SQLException {

		List<Disciplina> disciplinas = new ArrayList<>();
		disciplinas = cDao.buscaDisciplina(p);
		return disciplinas;

	}

	private int ValidaProfessor(Professor p) throws SQLException, ClassNotFoundException {
		return cDao.ValidaProfessor(p);
	}

}
