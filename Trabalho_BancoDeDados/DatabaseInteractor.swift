//
//  DatabaseInteractor.swift
//  Trabalho_BancoDeDados
//
//  Created by Caio Soares on 18/06/23.
//

import Foundation
import OHMySQL

class DatabaseInteractor {

    let defaults = UserDefaults.standard

    init() {
        let user = MySQLConfiguration(user: "root",
                                      password: "admin",
                                      serverName: "172.20.10.5",
                                      dbName: "modelo_lavanderia",
                                      port: 3306,
                                      socket: nil)
        print("Created MYSQL Config")
        self.coordinator = MySQLStoreCoordinator(configuration: user)
        print("Coordinator inited")
        coordinator.encoding = .UTF8MB4
        print("Trying to connect...")
        coordinator.connect()
        print("Connected!")
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
            print("user apparently exists")
            defaults.setValue(username, forKey: "user")
            defaults.setValue(cpf, forKey: "cpf")
            defaults.setValue(contato, forKey: "contato")
            defaults.setValue(true, forKey: "userExists")
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
        print("Coming from user defaults -> \(currentlyDefaultUser)")
        print("Coming from MySQL -> \(response.first)")

        if let unwrappedDict = response.first {
            let areEqual = currentlyDefaultUser.keys.allSatisfy { key in
                currentlyDefaultUser[key] as? AnyHashable == unwrappedDict[key] as? AnyHashable
            }
            if areEqual { print("User is valid!") ; return true }
        } else {
            print("MySQL response is empty. Logging out...")
            self.nukeAccount()
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

    func nukeAccount() {
        defaults.removeObject(forKey: "user")
        defaults.removeObject(forKey: "cpf")
        defaults.removeObject(forKey: "contato")
        defaults.removeObject(forKey: "userExists")
        print("Nuked Account")
    }

    //    func fetchAllCleaning() -> [Cleaning] {
    //
    //    }


}

extension DatabaseInteractor {

    func createMachine() {

        let random = Int.random(in: 1...3)
        let randomid = "\(random)\(Int.random(in: 000_000...999_999))"
        let randomcap = "\(random * 10)"
        let randompre = "\(random * 25)"

        let query = MySQLQueryRequestFactory.insert("maquina_lavar", set:
                                                        ["maquina_numero" : randomid,
                                                         "maquina_tipo": "maquina \(randomid)",
                                                         "maquina_capacidade": randomcap,
                                                         "maquina_disponibilidade": "1",
                                                         "maquina_preco": randompre])


        var resp = [[String: Any]]()

        do {
            _ = try context.execute(query)
        } catch {
            print(resp)
        }

    }

    func fetchMachine() -> [Maquina] {

        let query = MySQLQueryRequest(query: "SELECT `maquina_numero`, `maquina_tipo`, `maquina_capacidade`, `maquina_disponibilidade`, `maquina_preco` FROM `maquina_lavar` WHERE 1")

        var response = [[String: Any]]()

        do {
            response = try context.executeQueryRequestAndFetchResult(query)
            response = response.sorted { dict1, dict2 in
                guard let id1 = dict1["maquina_numero"] as? Int,
                      let id2 = dict2["maquina_numero"] as? Int else {
                    return false // If 'maquina_numero' is not an integer, treat it as a lower value
                }
                return id1 < id2
            }
            response = response.map { dict -> [String: Any] in
                let sortedDict = dict.sorted(by: { $0.key < $1.key })
                return Dictionary(uniqueKeysWithValues: sortedDict)
            }

            var responses = [Maquina]()

            for dict in response {
                if let maquinaNumero = dict["maquina_numero"] as? Int,
                   let maquinaTipo = dict["maquina_tipo"] as? String,
                   let maquinaCapacidade = dict["maquina_capacidade"] as? Int,
                   let maquinaDisponibilidade = dict["maquina_disponibilidade"] as? Int,
                   let maquinaPreco = dict["maquina_preco"] as? Int {

                    let maquina = Maquina(maquina_numero: maquinaNumero,
                                          maquina_tipo: maquinaTipo,
                                          maquina_capacidade: maquinaCapacidade,
                                          maquina_disponibilidade: maquinaDisponibilidade,
                                          maquina_preco: maquinaPreco)

                    responses.append(maquina)

                } else {
                    print("Failed to decode the dictionary")
                }
            }
            print(responses)
            return responses
        } catch {
            print("Could not find this CPF in DB")
            fatalError()
        }

    }

    func updateMachine(_ id: Int, _ val: Bool) {

        let updateQuery = MySQLQueryRequestFactory.update("maquina_lavar", set: ["maquina_disponibilidade": NSNumber(value: val)], condition: "maquina_numero = \(id)")

        do {
            try context.execute(updateQuery)
            print("updated successfully!")
        } catch {
            print("Failed to update: \(error)")
        }
    }

}

extension DatabaseInteractor {

    func createScheduling(maqNum: Int, clnCPF: String) {

        let random = Int.random(in: 1...3)
        let randomid = "\(random)\(Int.random(in: 000_000...999_999))"
        let randompre = "\(random * 25)"

        let query = MySQLQueryRequestFactory.insert("agendamento", set:
                                                        ["idagendamento" : randomid,
                                                         "maquina_numero": maqNum,
                                                         "cliente_cpf": clnCPF,
                                                         "agendamento_data": "tomorrow",
                                                         "agendamento_preco": randompre])

        do {
            try context.execute(query)
            print("created scheduling successfully!")
        } catch {
            print("Failed to create scheduling: \(error)")
        }
    }

    func deleteScheduling(_ id: Int) {

//        let query = MySQLQueryRequestFactory.delete("agendamento", condition: "WHERE `idagendamento` = \(id)")
        let query = MySQLQueryRequest(query: "DELETE FROM agendamento WHERE `agendamento`.`idagendamento` = \(id)")

        do {
            try context.execute(query)
            print("deleted scheduling successfully!")
        } catch {
            print("Failed to delete scheduling: \(error)")
        }

    }

    func fetchScheduling() -> [Cleaning] {

        let query = MySQLQueryRequest(query: "SELECT `idagendamento`, `maquina_numero`, `cliente_cpf`, `agendamento_data`, `agendamento_preco` FROM `agendamento` WHERE 1")

        var response = [[String: Any]]()

        do {
            response = try context.executeQueryRequestAndFetchResult(query)
            response = response.sorted { dict1, dict2 in
                guard let id1 = dict1["maquina_numero"] as? Int,
                      let id2 = dict2["maquina_numero"] as? Int else {
                    return false // If 'maquina_numero' is not an integer, treat it as a lower value
                }
                return id1 < id2
            }
            response = response.map { dict -> [String: Any] in
                let sortedDict = dict.sorted(by: { $0.key < $1.key })
                return Dictionary(uniqueKeysWithValues: sortedDict)
            }
            print(response)
            var responses = [Cleaning]()

            for dict in response {
                if let idagendamento = dict["idagendamento"] as? Int,
                   let maquina_numero = dict["maquina_numero"] as? Int,
                   let cliente_cpf = dict["cliente_cpf"] as? String,
                   let agendamento_data = dict["agendamento_data"] as? String,
                   let agendamento_preco = dict["agendamento_preco"] as? Int {

                    let cleaning = Cleaning(idagendamento: idagendamento,
                                            maquina_numero: maquina_numero,
                                            cliente_cpf: cliente_cpf,
                                            agendamento_data: agendamento_data,
                                            agendamento_preco: agendamento_preco)

                    responses.append(cleaning)
                } else {
                    print("Failed to decode the dictionary")
                }
            }
            print(responses)
            return responses
        } catch {
            print("Could not fetch scheduling in DB")
            fatalError()
        }

    }

}

extension DatabaseInteractor {

    func performInnerJoin() {

        let query = MySQLQueryRequest(query: "SELECT * FROM maquina_lavar JOIN agendamento ON maquina_lavar.maquina_numero = agendamento.maquina_numero")


        var response = [[String: Any]]()

        do {
            response = try context.executeQueryRequestAndFetchResult(query)
            print(response)
        } catch {
            print("failed to inner join")
        }


    }

}
