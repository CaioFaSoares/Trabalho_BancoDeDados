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
            }

            VStack {
                
            }.tabItem {
                Image(systemName: "clock.circle")
                Text("Agendar")
            }.onAppear {

            }

            VStack {
                
            }.tabItem {
                Image(systemName: "bubbles.and.sparkles.fill")
                Text("Consultar fila")
            }
            
            VStack {
                
            }.tabItem {
                Image(systemName: "person.circle")
                Text("Painel")
            }
        }
    }
}

extension ContentView {

    @MainActor class ViewModel: ObservableObject {

        init() {
            self.db = DatabaseInteractor.shared
            db.checkIfUserExists(username: db.defaults.string(forKey: "user") ?? "", cpf: db.defaults.string(forKey: "cpf") ?? "", contato: db.defaults.string(forKey: "contato") ?? "")
        }

        public var db: DatabaseInteractor!

        // MARK: - First tab view stuff

        @Published var username = ""
        @Published var cpf      = ""
        @Published var contato  = ""

        @Published var warning  = ""


        // MARK: - Second tab view stuff

    }
}

class DatabaseInteractor {

    let defaults = UserDefaults.standard

    init() {
        let user = MySQLConfiguration(user: "root",
                                      password: "admin",
                                      serverName: "192.168.0.4",
                                      dbName: "modelo_lavanderia",
                                      port: 3306,
                                      socket: nil)

        self.coordinator = MySQLStoreCoordinator(configuration: user)
        coordinator.encoding = .UTF8MB4
        coordinator.connect()
        self.context.storeCoordinator = coordinator
    }

    static var shared = DatabaseInteractor()
    let context = MySQLQueryContext()
    let coordinator: MySQLStoreCoordinator!

}

extension DatabaseInteractor {

    func createAccount(username: String, cpf: String, contato: String, warning: inout String) {
        if username == "" || cpf == "" || contato == "" { warning = "No field can be empty!"; return }
        if username.count > 90 { warning = "Username should be under 90 chars!"; return  }
        if cpf.count > 14 { warning = "CPF should be under 14 chars!"; return  }
        if contato.count > 14 { warning = "Contato should be under 14 chars!"; return  }

        if checkIfUserExists(username: username, cpf: cpf, contato: contato) {
            warning = "User already exists!"
            return
        }

        let query = MySQLQueryRequestFactory.insert("cliente", set:
                                                        ["cliente_nome" : username,
                                                         "cliente_cpf": cpf,
                                                         "cliente_contato": contato])

        do {
            try context.execute(query)
            defaults.setValue(username, forKey: "user")
            defaults.setValue(cpf, forKey: "cpf")
            defaults.setValue(contato, forKey: "contato")
            defaults.setValue(true, forKey: "userExists")
            print("Created account!")
        } catch {
            defaults.setValue(false, forKey: "userExists")
        }

    }

    func checkIfUserExists(username: String, cpf: String, contato: String) -> Bool {

        guard let currentCPF = defaults.value(forKey: "cpf") else { print("No CPF currently Defaulted") ; return false }

        let query = MySQLQueryRequest(query: "SELECT * FROM cliente WHERE cliente_cpf = \(currentCPF)")
//            (query: "SELECT * FROM cliente WHERE cliente_cpf = :cpf", condition: currentlyDefaultedUser)

        let response: [[String: Any]]

        do {
            response = try context.executeQueryRequestAndFetchResult(query)
        } catch {
            print("Could not find this CPF in DB")
            fatalError()
        }

        let currentlyDefaultUser: [String: Any] = ["cliente_contato": defaults.value(forKey: "contato"),
                                                   "cliente_nome": defaults.value(forKey: "user"),
                                                   "cliente_cpf": defaults.value(forKey: "cpf")]
        print(currentlyDefaultUser)
        print(response.first)

        if let unwrappedDict = response.first {
            let areEqual = currentlyDefaultUser.keys.allSatisfy { key in
                currentlyDefaultUser[key] as? AnyHashable == unwrappedDict[key] as? AnyHashable
            }
            if areEqual { print("User is valid!") ; return true }
        } else {
            print("dict2 is nil")
        }

        return true

    }

    func scheduleCleaning(machine: Int, date: Date, preco: Int) {
        let query = MySQLQueryRequestFactory.insert("agendamento", set:
                                                        ["idagendamento" : UUID(),
                                                         "maquina_numero": machine,
                                                         "cliente_cpf": defaults.string(forKey: "cpf"),
                                                         "agendamento_data": date,
                                                         "agendamento_preço": preco])
    }

//    func fetchAllCleaning() -> [Cleaning] {
//
//    }


}

struct Cleaning {

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
