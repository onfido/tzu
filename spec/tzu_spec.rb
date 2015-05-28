# require 'spec_helper'
#
# if !defined?(ActiveRecord::Base)
#   puts "** require 'active_record' to run the specs in #{__FILE__}"
# else
#   ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
#
#   ActiveRecord::Migration.suppress_messages do
#     ActiveRecord::Schema.define(:version => 0) do
#       create_table(:employers, force: true) {|t| t.string :name }
#       create_table(:users, force: true) {|t| t.string :first_name; t.string :last_name; t.references :employer; }
#       create_table(:sports_cars, force: true) {|t| t.string :make; t.references :employer; }
#     end
#   end
#
#   module GetSpec
#     class Employer < ActiveRecord::Base
#       has_many :users
#       has_many :sports_cars
#     end
#
#     class User < ActiveRecord::Base
#       belongs_to :employer
#     end
#
#     class SportsCar < ActiveRecord::Base
#       belongs_to :employer
#     end
#   end
# end
#
# describe Get do
#   let(:last_name) { 'Turner' }
#   let(:adapter) { :active_record }
#
#   # Preserve system config for other tests
#   before(:all) { @system_config = Get.configuration }
#   after(:all) { Get.configuration = @system_config }
#
#   # Reset base config with each iteration
#   before { Get.configure { |config| config.set_adapter(adapter) } }
#   after do
#     GetSpec::User.delete_all
#     GetSpec::Employer.delete_all
#     Get.reset
#   end
#
#   class MyCustomEntity < Horza::Entities::Collection
#     def east_london_length
#       "#{length}, bruv"
#     end
#   end
#
#   describe '#configure' do
#     context '#register_entity' do
#       let(:user_count) { 3 }
#
#       before do
#         Get.configure { |config| config.register_entity(:users_by_last_name, MyCustomEntity) }
#         user_count.times { GetSpec::User.create(last_name: last_name) }
#       end
#       after { Get.reset }
#
#       it 'gets registers entity' do
#         expect(Get.configuration.entity_for(:users_by_last_name)).to eq MyCustomEntity
#       end
#
#       it 'returns specified entity type after querying db' do
#         result = Get::UsersByLastName.run(last_name)
#         expect(result.is_a? MyCustomEntity).to be true
#         expect(result.east_london_length).to eq "#{user_count}, bruv"
#       end
#     end
#   end
#
#   context '#entity_for' do
#     context 'when entity has been registered' do
#       before do
#         Get.configure do |config|
#           config.set_adapter(adapter)
#           config.register_entity(:users_by_last_name, MyCustomEntity)
#         end
#       end
#       after { Get.reset }
#
#       it 'registers entity' do
#         expect(Get.entity_for(:users_by_last_name)).to eq MyCustomEntity
#       end
#     end
#
#     context 'when entity has not been registered' do
#       it 'returns nil' do
#         expect(Get.entity_for(:users_by_last_name)).to be nil
#       end
#     end
#   end
#
#   context '#adapter' do
#     context 'when the adapter is set' do
#       it 'returns the correct adapter class' do
#         expect(Get.adapter).to eq Horza::Adapters::ActiveRecord
#       end
#     end
#
#     context 'when the adapter is not set' do
#       before { Get.reset }
#       after { Get.reset }
#
#       it 'throws error' do
#         expect { Get.adapter }.to raise_error(Get::Errors::Base)
#       end
#     end
#   end
#
#   context '#reset' do
#     before do
#       Get.configure do |config|
#         config.set_adapter('my_adapter')
#         config.register_entity(:users_by_last_name, MyCustomEntity)
#       end
#       Get.reset
#     end
#     it 'resets the config' do
#       expect(Get.configuration.adapter).to be nil
#       expect(Get.entity_for(:users_by_last_name)).to be nil
#     end
#   end
#
#   context '#run!' do
#     context 'singular form' do
#       context 'when the record exists' do
#         let!(:user) { GetSpec::User.create(last_name: last_name) }
#
#         context 'field in class name' do
#           it 'gets the records based on By[KEY]' do
#             result = Get::UserById.run!(user.id)
#             expect(result.to_h).to eq user.attributes
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UserById.run!(user.id).is_a?(Horza::Entities::Single)).to be true
#           end
#         end
#
#         context 'field in parameters' do
#           it 'gets the records based on parameters' do
#             result = Get::UserBy.run!(last_name: last_name)
#             expect(result.to_h).to eq user.attributes
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UserBy.run!(last_name: last_name).is_a?(Horza::Entities::Single)).to be true
#           end
#         end
#       end
#
#       context 'when the record does not exist' do
#         it 'returns nil' do
#           expect { Get::UserById.run!(999) }.to raise_error Get::Errors::Base
#         end
#       end
#     end
#
#     context 'ancestry' do
#       context 'valid ancestry with no saved parent' do
#         let(:user2) { GetSpec::User.create }
#         it 'returns nil' do
#           expect { Get::EmployerFromUser.run!(user2) }.to raise_error Get::Errors::RecordNotFound
#         end
#       end
#     end
#   end
#
#   context '#run' do
#     context 'singular form' do
#       context 'when the record exists' do
#         let!(:user) { GetSpec::User.create(last_name: last_name) }
#
#         context 'field in class name' do
#           it 'gets the records based on By[KEY]' do
#             result = Get::UserById.run(user.id)
#             expect(result.to_h).to eq user.attributes
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UserById.run(user.id).is_a?(Horza::Entities::Single)).to be true
#           end
#         end
#
#         context 'field in parameters' do
#           it 'gets the records based on parameters' do
#             result = Get::UserBy.run(last_name: last_name)
#             expect(result.to_h).to eq user.attributes
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UserBy.run(last_name: last_name).is_a?(Horza::Entities::Single)).to be true
#           end
#         end
#       end
#
#       context 'when the record does not exist' do
#         it 'returns nil' do
#           expect(Get::UserById.run(999)).to eq nil
#         end
#       end
#     end
#
#     context 'plural form' do
#       let(:last_name) { 'Turner' }
#       let(:match_count) { 3 }
#       let(:miss_count) { 2 }
#
#       context 'when records exist' do
#         before do
#           match_count.times { GetSpec::User.create(last_name: last_name)  }
#           miss_count.times { GetSpec::User.create }
#         end
#
#         context 'field in class name' do
#           it 'gets the records based on By[KEY]' do
#             result = Get::UsersByLastName.run(last_name)
#             expect(result.length).to eq match_count
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UsersByLastName.run(last_name).is_a?(Horza::Entities::Collection)).to be true
#           end
#         end
#
#         context 'field in parameters' do
#           it 'gets the records based on parameters' do
#             result = Get::UsersBy.run(last_name: last_name)
#             expect(result.length).to eq match_count
#           end
#
#           it 'returns a dynamically generated response entity' do
#             expect(Get::UsersBy.run(last_name: last_name).is_a?(Horza::Entities::Collection)).to be true
#           end
#         end
#       end
#
#       context 'when no records exist' do
#         it 'returns empty collection' do
#           expect(Get::UsersBy.run(last_name: last_name).empty?).to be true
#         end
#       end
#     end
#
#     context 'ancestry' do
#       context 'direct relation' do
#         let(:employer) { GetSpec::Employer.create }
#         let!(:user1) { GetSpec::User.create(employer: employer) }
#         let!(:user2) { GetSpec::User.create(employer: employer) }
#
#         context 'ParentFromChild' do
#           it 'returns parent' do
#             expect(Get::EmployerFromUser.run(user1).to_h).to eq employer.attributes
#           end
#         end
#
#         context 'ChildrenFromParent' do
#           it 'returns children' do
#             result = Get::UsersFromEmployer.run(employer)
#             expect(result.first.to_h).to eq user1.attributes
#             expect(result.last.to_h).to eq user2.attributes
#           end
#         end
#
#         context 'invalid ancestry' do
#           it 'throws error' do
#             expect { Get::UserFromEmployer.run(employer) }.to raise_error Get::Errors::InvalidAncestry
#           end
#         end
#
#         context 'valid ancestry with no saved childred' do
#           let(:employer2) { GetSpec::Employer.create }
#           it 'returns empty collection error' do
#             expect(Get::UsersFromEmployer.run(employer2).empty?).to be true
#           end
#         end
#
#         context 'valid ancestry with no saved parent' do
#           let(:user2) { GetSpec::User.create }
#           it 'returns nil' do
#             expect(Get::EmployerFromUser.run(user2)).to be nil
#           end
#         end
#       end
#
#       context 'using via' do
#         let(:employer) { GetSpec::Employer.create }
#         let(:user) { GetSpec::User.create(employer: employer) }
#         let(:sportscar) { GetSpec::SportsCar.create(employer: employer) }
#
#         before do
#           employer.sports_cars << sportscar
#         end
#
#         it 'returns the correct ancestor (single via symbol)' do
#           result = Get::SportsCarsFromUser.run(user, via: :employer)
#           expect(result.first.to_h).to eq sportscar.attributes
#         end
#
#         it 'returns the correct ancestor (array of via symbols)' do
#           result = Get::SportsCarsFromUser.run(user, via: [:employer])
#           expect(result.first.to_h).to eq sportscar.attributes
#         end
#       end
#     end
#   end
# end
#
# describe Get::Builders::AncestryBuilder do
#   let(:name) { 'UserFromEmployer' }
#
#   before { Get.configure { |config| config.set_adapter(:active_record) } }
#   after { Get.reset }
#
#   subject { Get::Builders::AncestryBuilder.new(name) }
#
#   describe '#class' do
#     it 'builds a class that inherits from Get::Db' do
#       expect(subject.class.superclass).to eq Get::Db
#     end
#
#     it 'correctly assigns class-level variables' do
#       [:entity, :query_key, :collection, :store, :result_key].each do |class_var|
#         expect(subject.class.respond_to? class_var).to be true
#       end
#     end
#   end
# end
#
# describe Get::Builders::QueryBuilder do
#   let(:name) { 'UserFromEmployer' }
#
#   before { Get.configure { |config| config.set_adapter(:active_record) } }
#   after { Get.reset }
#
#   subject { Get::Builders::QueryBuilder.new(name) }
#
#   describe '#class' do
#     it 'builds a class that inherits from Get::Db' do
#       expect(subject.class.superclass).to eq Get::Db
#     end
#
#     it 'correctly assigns class-level variables' do
#       [:entity, :query_key, :collection, :store, :field].each do |class_var|
#         expect(subject.class.respond_to? class_var).to be true
#       end
#     end
#   end
# end
