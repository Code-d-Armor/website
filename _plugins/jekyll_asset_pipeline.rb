require 'jekyll_asset_pipeline'

module JekyllAssetPipeline
    class SassConverter < JekyllAssetPipeline::Converter
      require 'sassc'
  
      def self.filetype
        '.scss'
      end
  
      def convert
        return Sass::Engine.new(@content, syntax: :scss, load_paths: [@dirname]).render
      end
    end
  end