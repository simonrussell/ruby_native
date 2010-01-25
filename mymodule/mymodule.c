#include <ruby.h>
static VALUE mymethod(VALUE self) {
  return 
(RTEST(rb_str_new2("a")) ? rb_str_new2("b") : rb_str_new2("c"))
;
}

void Init_mymodule(void)
{
  VALUE module = rb_define_module("Mymodule");

  rb_define_module_function(module, "run", mymethod, 0);
}
