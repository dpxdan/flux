<? extend('left_panel_master.php') ?>
<? startblock('extra_head') ?>
<script type="text/javascript" language="javascript">
    $(document).ready(function() {
      
        build_grid("charges_history_grid","",<? echo $grid_fields; ?>,"");
        $("#charges_search_btn").click(function(){
            post_request_for_search("charges_history_grid","","user_charge_history_search");
        });        
        $("#id_reset").click(function(){
            clear_search_request("charges_history_grid","");
        });
        var currentdate = new Date(); 
       var datetime = currentdate.getFullYear() + "-"
            + ('0' + (currentdate.getMonth()+1)).slice(-2) + "-" 
                + ("0" + currentdate.getDate()).slice(-2) + " 00:00:00";  
        var datetime1 = currentdate.getFullYear() + "-"
           +('0' + (currentdate.getMonth()+1)).slice(-2) + "-" 
            + ("0" + currentdate.getDate()).slice(-2) + " 23:59:59";
        $("#charge_from_date").datetimepicker({
             value:datetime,
            uiLibrary: 'bootstrap4',
            iconsLibrary: 'fontawesome',
            modal:true,
            format: 'yyyy-mm-dd HH:MM:ss',
            footer:true
         });  
         $("#charge_to_date").datetimepicker({
             value:datetime1,
            uiLibrary: 'bootstrap4',
            iconsLibrary: 'fontawesome',
            modal:true,
            format: 'yyyy-mm-dd HH:MM:ss',
            footer:true
         });   
        
    });
</script>
<script type="text/javascript">
  $(document).ready(function(){
      $(".breadcrumb li a").removeAttr("data-ripple",""); 
  });
</script>
<? endblock() ?>
<? startblock('page-title') ?>
<?= $page_title ?>
<? endblock() ?>
<? startblock('content') ?>         
  <div id="main-wrapper">  
    <div id="content" class="container-fluid">   
        <div class="row"> 
            <div class="col-md-12 color-three border_box"> 
                <div class="float-left m-2 lh19">
                   <nav aria-label="breadcrumb">
					    <ol class="breadcrumb m-0 p-0">
                         <li class="breadcrumb-item"><a href="<?= base_url() . "user/user_myprofile/"; ?>">My Profile</a></li>
						 <li class="breadcrumb-item active">
                             <a href="<?= base_url() . "user/user_charges_history/"; ?>"><?php echo gettext('Charges History')?></a>
                          </li>
                        </ol>
                    </nav>
                </div>
				<div class="m-2 float-right">
					<a class="btn btn-light btn-hight" href="<?= base_url()."user/user_myprofile/"; ?>"> <i class="fa fa-fast-backward" aria-hidden="true"></i><?php echo gettext('Back'); ?></a>
                </div>
            </div>     
			<div class="p-4 col-md-12">
					<div class="col-md-12 p-0">
							<div  id="show_search" class= "btn btn-warning float-right"><i class="fa fa-search"></i> <?php echo gettext('Search');?> </div>
					</div> 
                    <div class="col-12">
                                <div class="portlet-content my-4"  id="search_bar" style="display:none">
                                        <?php echo $form_search; ?>
                                </div>
                    </div>
                    <div class="col-12 px-4">
                        <div class="card px-4 pb-4">
                                <table id="charges_history_grid" align="left" style="display:none;"></table>
                        </div>
                    </div>
            </div>
        </div>
    </div>
</div>
<? endblock() ?>	
<? end_extend() ?>  
<script type="text/javascript">
  $(document).ready(function(){
      $('.page-wrap').addClass('addon_wrap');
  });
</script>
