class MenuController < ApplicationController
  before_filter :authenticate_user!
  
  
  def new
    @menu_item = MenuItem.new
  end


  def create
    @menu_item = MenuItem.new(menu_params)
    user = current_user.id
    @menu_item.user_id = user
    build_your_own = params["menu_item"]["is_build_your_own"]
    
    if build_your_own == "1" and @menu_item.save      
      
      new_groups = params["menu_group_num"]
      
      for i in 0..new_groups.length - 1
        group_name = params["group_name_" + new_groups[i]]
        group_price = params["additional_price_" + new_groups[i]]
        group_max = params["max_allowed_" + new_groups[i]]
        menu_group = MenuItemContentGroup.create(MenuItem_id: @menu_item.id, name: group_name, additional_price: group_price, max_allowed: group_max)
        
        menu_group_content = params["menuitemcontent" + new_groups[i]]
        
        for j in 0..menu_group_content.length - 1
          MenuItemContent.create(MenuContentGroup_id: menu_group.id, ingredient: menu_group_content[j])
        end
      end
    
    elsif @menu_item.save
        format.html { redirect_to bid_path(@menu_item.id), notice: 'Menu Item was successfully submitted.' }
        format.json { render :show, status: :created, location: @menu_item }
    else
        format.html { render :new }
        format.json { render json: @menu_item.errors, status: :unprocessable_entity }
    end
  end

  
  def edit
    @menu_item = MenuItem.find_by!(id: params[:id], user_id: current_user.id)
  end
  
  
  def update
    @menu_item = MenuItem.find_by!(id: params[:id], user_id: current_user.id)
    build_your_own = @menu_item.is_build_your_own
    
    if @menu_item.update(menu_params)
      
      #If not build your own remove all groups
      if build_your_own and !@menu_item.is_build_your_own
        @menu_item.delete_groups()
      end
      
      if @menu_item.is_build_your_own
        removed_groups = params["removed_record"]
        @menu_item.remove_groups(removed_groups)
        
        removed_content = params["removed_content"]
        @menu_item.remove_content(removed_content)
        
        menu_groups = @menu_item.MenuItemContentGroup.where(is_deleted: false)
        group_ids = params["group_id"]
        #update existing groups
        for i in 0..group_ids.size - 1
          begin
            menu_group = menu_groups.find(group_ids[i])
            menu_group.update(name: params["group_name_" + menu_group.id.to_s], max_allowed: params["max_allowed_" + menu_group.id.to_s], additional_price: params["additional_price_" + menu_group.id.to_s])
            menu_content = menu_group.MenuItemContent.where(is_deleted: false)
            
            #Update existing content
            for content in menu_content
              content.update(ingredient: params["menuitemcontent" + content.id.to_s])
            end
            
            #Add new content to group
            new_content = params["menuitemcontente" + menu_group.id.to_s]
            if new_content
              for j in 0..new_content.size - 1
                  MenuItemContent.create(MenuContentGroup_id: menu_group.id, ingredient: new_content[j])
              end
            end
          rescue ActiveRecord::RecordNotFound
          end
        end
        
        #Add new groups
        new_groups = params["menu_group_num"]
        if new_groups
          for i in 0..new_groups.count - 1
            group_name = params["group_name_" + new_groups[i].to_s]
            group_price = params["additional_price_" + new_groups[i].to_s]
            group_max = params["max_allowed_" + new_groups[i].to_s]
            menu_group = MenuItemContentGroup.create(MenuItem_id: @menu_item.id, name: group_name, additional_price: group_price, max_allowed: group_max)
            
            menu_group_content = params["menuitemcontent" + new_groups[i].to_s]
            
            for j in 0..menu_group_content.length - 1
              MenuItemContent.create(MenuContentGroup_id: menu_group.id, ingredient: menu_group_content[j])
            end
          end
        end
      end
    end
  end
  
  
  def show
      @menu_items = MenuItem.where(id: params[:id], is_deleted: false)
  end


  def index
    @menu_items = MenuItem.where(user_id: current_user.id, is_deleted: false)  
  end
  
  
  def destroy
    @menu_item = RequestCar.find_by!(:id=>params[:id], :user_id=>current_user.id)
    if @menu_item.present?
      @menu_item.is_deleted = false
    end
    respond_to do |format|
      format.html { redirect_to '/menu', notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  
  private

  def menu_params
    params.require(:menu_item).permit(:name, :description, :price, :is_build_your_own)
  end
end
