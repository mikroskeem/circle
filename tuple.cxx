#include <iostream>

template<typename... Ts>
struct tuple {
  // At instantiation, loop through each element in the parameter pack Ts.
  // Subscript the i'th element Ts...[i].
  // Declare a data member with name @(i): _0, _1, _2, etc.
  @meta for(int i : sizeof...(Ts))
    Ts...[i] @(i);
};

int main() {
  using MyTuple = tuple<int, char, float>;
  MyTuple my_tuple { 100, 'x', 3.14 };

  // Use Circle reflection to access the member names of a class object.
  // Use the pack slice operator ...[:] to convert an object into a pack.
  // Print each member name and value with a pack expansion.
  std::cout<< MyTuple.member_names<< ": "<< my_tuple...[:]<< "\n" ...;
}
