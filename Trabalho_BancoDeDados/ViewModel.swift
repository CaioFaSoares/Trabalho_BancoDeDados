//
//  ViewModel.swift
//  Trabalho_BancoDeDados
//
//  Created by Caio Soares on 18/06/23.
//

import Foundation

class ViewModel: ObservableObject {

    init() {
        self.db = DatabaseInteractor.shared
        _ = db.checkIfUserExists(username: db.defaults.string(forKey: "user") ?? "", cpf: db.defaults.string(forKey: "cpf") ?? "", contato: db.defaults.string(forKey: "contato") ?? "")
    }

    public var db: DatabaseInteractor!

    // MARK: - First tab view stuff

    @Published var username = ""
    @Published var cpf      = ""
    @Published var contato  = ""

    @Published var warning  = ""

    @Published var possibleMachines = [Maquina]()
    @Published var upcomingCleanings = [Cleaning]()


    // MARK: - Second tab view stuff

    func createMachine() {
        db.createMachine()
    }

    func updateMachine(_ id: Int, _ state: Bool) {
        db.updateMachine(id, state)
    }

    func createScheduling(_ num: Int, _ cpf: String) {
        db.createScheduling(maqNum: num, clnCPF: cpf)
    }

    func deleteScheduling(_ id: Int) {
        db.deleteScheduling(id)
    }

    // MARK: - Fourth tab stuff



}

struct Maquina: Equatable, Hashable {
    var maquina_numero: Int
    var maquina_tipo: String
    var maquina_capacidade: Int
    var maquina_disponibilidade: Int
    var maquina_preco: Int
}

struct Cleaning: Equatable, Hashable {
    let idagendamento: Int
    let maquina_numero: Int
    let cliente_cpf: String
    let agendamento_data: String
    let agendamento_preco: Int
    
}
