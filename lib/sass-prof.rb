# encoding: UTF-8

require "terminal-table"

require "sass-prof/config"
require "sass-prof/timer"
require "sass-prof/reporter"
require "sass-prof/formatter"
require "sass-prof/profiler"
require "sass-prof/fundef_profiler"
require "sass-prof/fun_profiler"
require "sass-prof/mixdef_profiler"
require "sass-prof/mix_profiler"
require "sass-prof/ext_profiler"
require "sass-prof/var_profiler"

# Monkey patch Sass to utilize Profiler
module Sass
  class Tree::Visitors::Perform

    #
    # Function definition
    #
    alias_method :__visit_function, :visit_function

    def visit_function(node)
      return __visit_function node if ::SassProf::Config.ignore.include? :fundef

      prof = ::SassProf::FundefProfiler.new(node.dup, :fundef, node.args.dup,
        @environment)
      prof.start

      value = __visit_function node

      prof.stop

      value
    end

    #
    # Mixin definition
    #
    alias_method :__visit_mixindef, :visit_mixindef

    def visit_mixindef(node)
      return __visit_mixindef node if ::SassProf::Config.ignore.include? :mixdef

      prof = ::SassProf::MixdefProfiler.new(node.dup, :mixdef, node.args.dup,
        @environment)
      prof.start

      value = __visit_mixindef node

      prof.stop

      value
    end

    #
    # Mixin perform
    #
    alias_method :__visit_mixin, :visit_mixin

    def visit_mixin(node)
      return __visit_mixin node if ::SassProf::Config.ignore.include? :mix

      prof = ::SassProf::MixProfiler.new(node.dup, :mix, node.args.dup,
        @environment)
      prof.start

      value = __visit_mixin node

      prof.stop

      value
    end
  end

  # class Selector::SimpleSequence
  #
  #   #
  #   # Extend perform
  #   #
  #   alias_method :__do_extend, :do_extend
  #
  #   def do_extend(extends, parent_directives, replace, seen)
  #     return __do_extend extends, parent_directives, replace,
  #       seen if ::SassProf::Config.ignore.include? :ext
  #
  #     prof = ::SassProf::ExtProfiler.new(self, :ext, nil,
  #       self)
  #     prof.start
  #
  #     value = __do_extend extends, parent_directives, replace, seen
  #
  #     prof.stop
  #
  #     value
  #   end
  # end

  class Script::Tree::Funcall

    #
    # Function perform
    #
    alias_method :__perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      return __perform_sass_fn function, args, splat,
        environment if ::SassProf::Config.ignore.include? :fun

      prof = ::SassProf::FunProfiler.new(function.dup, :fun, args.dup,
        environment.dup)
      prof.start

      value = __perform_sass_fn function, args, splat, environment

      prof.stop

      value
    end
  end

  class Environment

    #
    # Variable declare
    #
    alias_method :__set_var, :set_var

    def set_var(name, value)
      return __set_var name,
        value if ::SassProf::Config.ignore.include? :var

      prof = ::SassProf::VarProfiler.new(name.dup, :var, value.dup,
        self)
      prof.start

      value = __set_var name, value

      prof.stop

      value
    end

    #
    # Global variable declare
    #
    alias_method :__set_global_var, :set_global_var

    def set_global_var(name, value)
      return __set_global_var name,
        value if ::SassProf::Config.ignore.include? :var

      prof = ::SassProf::VarProfiler.new(name.dup, :var, value.dup,
        self)
      prof.start

      value = __set_global_var name, value

      prof.stop

      value
    end

    #
    # Local variable declare
    #
    alias_method :__set_local_var, :set_local_var

    def set_local_var(name, value)
      return __set_local_var name,
        value if ::SassProf::Config.ignore.include? :var

      prof = ::SassProf::VarProfiler.new(name.dup, :var, value.dup,
        self)
      prof.start

      value = __set_local_var name, value

      prof.stop

      value
    end
  end

  class Engine
    alias_method :__render, :render

    def render
      __render
    ensure
      ::SassProf::Reporter.print_report
      ::SassProf::Reporter.reset_report
    end
  end
end
