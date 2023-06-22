//
//  ContentView.swift
//  Trabalho_BancoDeDados
//
//  Created by Caio Soares on 14/06/23.
//

import SwiftUI
import OHMySQL

struct ContentView: View {

    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        TabView {
            if viewModel.db.defaults.bool(forKey: "userExists") == false {
                VStack {
                    TextField("nome", text: $viewModel.username)
                        .padding(.all)
                        .textFieldStyle(.roundedBorder)
                    TextField("cpf", text: $viewModel.cpf)
                        .padding(.all)
                        .textFieldStyle(.roundedBorder)
                    TextField("contato", text: $viewModel.contato)
                        .padding(.all)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Criar conta") {
                        viewModel.db.createAccount(username: viewModel.username, cpf: viewModel.cpf, contato: viewModel.contato, warning: &viewModel.warning)
                    }
                    Text(viewModel.warning)
                }.tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Cadastrar Conta")
                }
            } else {
                VStack {
                    Text("Bem vindo a Lavanderia do Ilustre Sr. Sapo Folha \(viewModel.db.defaults.string(forKey: "user") ?? "")").padding(.all).multilineTextAlignment(.center)
                    Spacer()
                    Form {
                        ForEach(viewModel.possibleMachines.filter { $0.maquina_disponibilidade == 1 }, id: \.self) { machine in
                            Button("Schedule cleaning for \(machine.maquina_numero)") {
                                viewModel.updateMachine(machine.maquina_numero, false)
                                viewModel.createScheduling(machine.maquina_numero, viewModel.db.defaults.string(forKey: "cpf")!)
                            }
                        }
                    }
                    Spacer()
                }.tabItem {
                    Image(systemName: "clock.circle")
                    Text("Agendar")
                }.onAppear {
                    viewModel.possibleMachines = viewModel.db.fetchMachine()
                }.onChange(of: viewModel.possibleMachines) { _ in
                    self.refreshable { }
                }

                VStack {
                    Text("Bem vindo a Lavanderia do Ilustre Sr. Sapo Folha \(viewModel.db.defaults.string(forKey: "user") ?? "")").padding(.all).multilineTextAlignment(.center)
                    Spacer()
                    Form {
                        ForEach(viewModel.upcomingCleanings, id: \.self) { cleaning in
                            Button("Mark cleaning \(cleaning.idagendamento) as done") {
                                viewModel.updateMachine(Int(exactly: cleaning.maquina_numero)!, true)
                                viewModel.deleteScheduling(Int(exactly: cleaning.idagendamento)!)
                            }
                        }
                    }
                }.tabItem {
                    Image(systemName: "bubbles.and.sparkles.fill")
                    Text("Consultar fila")
                }.onAppear {
                    viewModel.upcomingCleanings = viewModel.db.fetchScheduling()
                }.onChange(of: viewModel.possibleMachines) { _ in
                    self.refreshable { }
                }

                VStack {
                    Section {
                        Button("Logout") {
                            viewModel.db.nukeAccount()
                        }
                        Button("Create Machine") {
                            viewModel.db.createMachine()
                        }
                        Button("Fetch Machines") {
                            viewModel.db.fetchMachine()
                        }
                        Button("Perform Inner Join") {
                            viewModel.db.performInnerJoin()
                        }
                    }
                }.tabItem {
                    Image(systemName: "person.circle")
                    Text("Painel")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
