use starknet::ContractAddress;

#[starknet::interface]
pub trait ITodoList<TContractState> {
    fn addTodo(ref self: TContractState, description: felt252, deadline: u32) -> bool;

    fn updateTodo(ref self: TContractState, index: u8, description: felt252, deadline: u32) -> bool;

    fn getTodos(self: @TContractState) -> Array<Todo::Todo>;

    //added a returned value
    fn getTodo(self: @TContractState, index: u8) -> Todo::Todo;
}

#[starknet::contract]
mod Todo {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        todolist: LegacyMap::<u8, Todo>,
        todoId: u8
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Todo {
        id: u8,
        description: felt252,
        deadline: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl Todolist of super::ITodoList<ContractState> {
        fn addTodo(ref self: ContractState, description: felt252, deadline: u32) -> bool {
            let id = self.todoId.read();
            let currentId = id + 1;
            self._addTodo(currentId, description, deadline);
            self.todoId.write(currentId);
            true
        }

        fn updateTodo(
            ref self: ContractState, index: u8, description: felt252, deadline: u32
        ) -> bool {
            self._addTodo(index, description, deadline);
            true
        }

        fn getTodos(self: @ContractState) -> Array<Todo> {
            let mut todos = ArrayTrait::new();
            let count = self.todoId.read();
            let mut index: u8 = 1;

            while index < count
                + 1 {
                    let readTodo = self.todolist.read(index);
                    todos.append(readTodo);
                    index += 1;
                };

            todos
        }

        fn getTodo(self: @ContractState, index: u8) -> Todo {
            self.todolist.read(index)
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _addTodo(ref self: ContractState, currentId: u8, description: felt252, deadline: u32) {
            let todo = Todo { id: currentId, description: description, deadline: deadline };
            self.todolist.write(currentId, todo);
        }
    }
}
