# encoding: UTF-8

require "terminal-table"

require "sass-prof/config"
require "sass-prof/reporter"
require "sass-prof/formatter"
require "sass-prof/profiler"

# Monkey patch Sass to utilize Profiler
module Sass
  class Tree::Visitors::Perform
    alias_method :__visit_function, :visit_function

    def visit_function(node)
      prof = ::SassProf::Profiler.new(node.dup, :allocate)
      prof.start

      value = __visit_function node

      prof.stop

      value
    end
  end

  class Script::Tree::Funcall
    alias_method :__perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      prof = ::SassProf::Profiler.new(function.dup, :invoke, args.dup,
        environment.dup)
      prof.start

      value = __perform_sass_fn(
        function, args, splat, environment)

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
